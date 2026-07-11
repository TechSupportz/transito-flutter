#!/usr/bin/env bun

const DEFAULT_PROJECT_ID = 'transito-8f50c';
const DEFAULT_EMULATOR_HOST = '127.0.0.1';
const DEFAULT_AUTH_PORT = 9099;
const DEFAULT_FIRESTORE_PORT = 8088;
const LOCAL_AUTH_API_KEY = 'fake-api-key';
const LOCAL_PASSWORD = 'Password123';

const DEFAULT_SETTINGS_FIELDS = {
  accentColour: { stringValue: '0xFF7E6BFF' },
  isETAminutes: { booleanValue: true },
  isNearbyGrid: { booleanValue: true },
  showNearbyDistance: { booleanValue: true },
  defaultCollapsedFavourites: { booleanValue: false },
  themeMode: { stringValue: 'SYSTEM' },
};

const DEFAULT_FAVOURITES_FIELDS = {
  favouritesList: { arrayValue: { values: [] } },
};

function printUsage() {
  console.log(`Usage:
  bun tool/copy_prod_user_to_emulator.mjs <production-user-id> [options]

Options:
  --email <email>              Local email (defaults to transito-<uid>@local.test)
  --emulator-host <host>       Emulator host (default: ${DEFAULT_EMULATOR_HOST})
  --auth-port <port>            Auth emulator port (default: ${DEFAULT_AUTH_PORT})
  --firestore-port <port>      Firestore emulator port (default: ${DEFAULT_FIRESTORE_PORT})
  --project-id <project-id>    Firebase project ID (default: ${DEFAULT_PROJECT_ID})
  --help                       Show this help

Production access uses the token from:
  gcloud auth application-default print-access-token
  or gcloud auth print-access-token
`);
}

function parseArgs(args) {
  if (args.includes('--help') || args.includes('-h')) {
    printUsage();
    return null;
  }

  const positional = [];
  const options = {
    email: null,
    emulatorHost: DEFAULT_EMULATOR_HOST,
    authPort: DEFAULT_AUTH_PORT,
    firestorePort: DEFAULT_FIRESTORE_PORT,
    projectId: DEFAULT_PROJECT_ID,
  };

  const optionNames = new Map([
    ['--email', 'email'],
    ['--emulator-host', 'emulatorHost'],
    ['--auth-port', 'authPort'],
    ['--firestore-port', 'firestorePort'],
    ['--project-id', 'projectId'],
  ]);

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    const optionName = optionNames.get(arg);

    if (!optionName) {
      if (arg.startsWith('--')) {
        throw new Error(`Unknown option: ${arg}`);
      }
      positional.push(arg);
      continue;
    }

    const value = args[index + 1];
    if (!value || value.startsWith('--')) {
      throw new Error(`${arg} requires a value`);
    }
    options[optionName] = value;
    index += 1;
  }

  if (positional.length !== 1) {
    printUsage();
    throw new Error('Enter exactly one production Firebase user ID');
  }

  const productionUserId = positional[0];
  if (!/^[A-Za-z0-9_-]+$/.test(productionUserId)) {
    throw new Error('The production user ID contains unsupported characters');
  }

  for (const optionName of ['authPort', 'firestorePort']) {
    options[optionName] = Number(options[optionName]);
    if (!Number.isInteger(options[optionName]) || options[optionName] < 1) {
      throw new Error(`${optionName} must be a valid port`);
    }
  }

  return { productionUserId, ...options };
}

function getProductionAccessToken() {
  if (process.env.FIREBASE_ACCESS_TOKEN) {
    return process.env.FIREBASE_ACCESS_TOKEN.trim();
  }

  const commands = [
    ['gcloud', ['auth', 'application-default', 'print-access-token']],
    ['gcloud', ['auth', 'print-access-token']],
  ];

  for (const [command, args] of commands) {
    const result = Bun.spawnSync([command, ...args], {
      stdout: 'pipe',
      stderr: 'ignore',
    });
    const token = new TextDecoder().decode(result.stdout).trim();
    if (result.exitCode === 0 && token) {
      return token;
    }
  }

  throw new Error(
    'Could not obtain a Google access token. Run `gcloud auth application-default login` '
      + 'or set FIREBASE_ACCESS_TOKEN.',
  );
}

function firestoreDocumentUrl({ projectId, collection, userId, host, port, production }) {
  const baseUrl = production
    ? `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(projectId)}`
    : `http://${host}:${port}/v1/projects/${encodeURIComponent(projectId)}`;

  return `${baseUrl}/databases/(default)/documents/${collection}/${encodeURIComponent(userId)}`;
}

async function requestJson(url, { method = 'GET', headers = {}, body } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      Accept: 'application/json',
      ...headers,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const responseText = await response.text();
  let responseBody = null;
  if (responseText) {
    try {
      responseBody = JSON.parse(responseText);
    } catch {
      responseBody = responseText;
    }
  }

  if (!response.ok) {
    const details = typeof responseBody === 'string' ? responseBody : JSON.stringify(responseBody);
    throw new Error(`${method} ${url} failed with HTTP ${response.status}: ${details}`);
  }

  return responseBody;
}

async function readProductionDocument({ accessToken, projectId, collection, userId }) {
  const url = firestoreDocumentUrl({ projectId, collection, userId, production: true });
  const response = await fetch(url, {
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (response.status === 404) {
    return null;
  }

  const responseText = await response.text();
  let responseBody = null;
  if (responseText) {
    try {
      responseBody = JSON.parse(responseText);
    } catch {
      responseBody = responseText;
    }
  }

  if (!response.ok) {
    const details = typeof responseBody === 'string' ? responseBody : JSON.stringify(responseBody);
    throw new Error(`Production read of ${collection}/${userId} failed with HTTP ${response.status}: ${details}`);
  }

  return responseBody;
}

function makeLocalEmail(productionUserId) {
  return `transito-${productionUserId}@local.test`;
}

async function createLocalAuthUser({ email, password, projectId, host, port }) {
  const authBaseUrl = `http://${host}:${port}/identitytoolkit.googleapis.com/v1`;
  const signUpUrl = `${authBaseUrl}/accounts:signUp?key=${LOCAL_AUTH_API_KEY}`;
  let response = null;

  try {
    response = await requestJson(signUpUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: { email, password, returnSecureToken: true },
    });

    const verifyUrl = `${authBaseUrl}/projects/${encodeURIComponent(projectId)}/accounts:update?key=${LOCAL_AUTH_API_KEY}`;
    await requestJson(verifyUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer owner',
      },
      body: {
        localId: response.localId,
        emailVerified: true,
      },
    });

    const signInUrl = `${authBaseUrl}/accounts:signInWithPassword?key=${LOCAL_AUTH_API_KEY}`;
    const signedInResponse = await requestJson(signInUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: { email, password, returnSecureToken: true },
    });

    return {
      localUserId: response.localId,
      idToken: signedInResponse.idToken,
    };
  } catch (error) {
    if (response?.localId) {
      await deleteLocalAuthUserByLocalId({
        projectId,
        localUserId: response.localId,
        host,
        port,
      }).catch(() => undefined);
    }
    throw error;
  }
}

async function writeLocalDocument({ projectId, collection, userId, fields, idToken, host, port }) {
  const url = firestoreDocumentUrl({
    projectId,
    collection,
    userId,
    host,
    port,
    production: false,
  });

  await requestJson(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: { fields },
  });
}

async function deleteLocalDocument({ projectId, collection, userId, idToken, host, port }) {
  const url = firestoreDocumentUrl({
    projectId,
    collection,
    userId,
    host,
    port,
    production: false,
  });

  await requestJson(url, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${idToken}` },
  });
}

async function deleteLocalAuthUser({ idToken, host, port }) {
  const url = `http://${host}:${port}/identitytoolkit.googleapis.com/v1/accounts:delete?key=${LOCAL_AUTH_API_KEY}`;
  await requestJson(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: { idToken },
  });
}

async function deleteLocalAuthUserByLocalId({ projectId, localUserId, host, port }) {
  const url = `http://${host}:${port}/identitytoolkit.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/accounts:delete?key=${LOCAL_AUTH_API_KEY}`;
  await requestJson(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: 'Bearer owner',
    },
    body: { localId: localUserId },
  });
}

function favouriteCount(fields) {
  return fields?.favouritesList?.arrayValue?.values?.length ?? 0;
}

async function copyUser(config) {
  const accessToken = getProductionAccessToken();
  const [productionSettings, productionFavourites] = await Promise.all([
    readProductionDocument({
      accessToken,
      projectId: config.projectId,
      collection: 'settings',
      userId: config.productionUserId,
    }),
    readProductionDocument({
      accessToken,
      projectId: config.projectId,
      collection: 'favourites',
      userId: config.productionUserId,
    }),
  ]);

  if (!productionSettings && !productionFavourites) {
    throw new Error(
      `No settings or favourites documents were found for production user ${config.productionUserId}`,
    );
  }

  if (!productionSettings) {
    console.warn('⚠️  settings document is missing; using the app defaults.');
  }
  if (!productionFavourites) {
    console.warn('⚠️  favourites document is missing; using an empty favourites list.');
  }

  const email = config.email ?? makeLocalEmail(config.productionUserId);
  const password = LOCAL_PASSWORD;
  const localAuthUser = await createLocalAuthUser({
    email,
    password,
    projectId: config.projectId,
    host: config.emulatorHost,
    port: config.authPort,
  });

  const localUserId = localAuthUser.localUserId;
  const documents = [
    {
      collection: 'settings',
      fields: productionSettings?.fields ?? DEFAULT_SETTINGS_FIELDS,
    },
    {
      collection: 'favourites',
      fields: productionFavourites?.fields ?? DEFAULT_FAVOURITES_FIELDS,
    },
  ];

  try {
    for (const document of documents) {
      await writeLocalDocument({
        projectId: config.projectId,
        collection: document.collection,
        userId: localUserId,
        fields: document.fields,
        idToken: localAuthUser.idToken,
        host: config.emulatorHost,
        port: config.firestorePort,
      });
    }
  } catch (error) {
    console.warn('⚠️  Copy failed; cleaning up the partially-created local user.');
    await Promise.allSettled(
      documents.map((document) =>
        deleteLocalDocument({
          projectId: config.projectId,
          collection: document.collection,
          userId: localUserId,
          idToken: localAuthUser.idToken,
          host: config.emulatorHost,
          port: config.firestorePort,
        }),
      ),
    );
    await deleteLocalAuthUser({
      idToken: localAuthUser.idToken,
      host: config.emulatorHost,
      port: config.authPort,
    }).catch(() => undefined);
    throw error;
  }

  return {
    localUserId,
    email,
    password,
    favouriteCount: favouriteCount(documents[1].fields),
  };
}

async function main() {
  const config = parseArgs(process.argv.slice(2));
  if (config === null) return;

  console.log(`Reading production data for user ${config.productionUserId}...`);
  const result = await copyUser(config);

  console.log('\n✅ Copied user data to the Firebase emulators.');
  console.log(`Local UID: ${result.localUserId}`);
  console.log(`Local email: ${result.email}`);
  console.log(`Local password: ${result.password}`);
  console.log(`Favourites copied: ${result.favouriteCount}`);
  console.log('\nUse the local email/password above to sign in through the app.');
}

main().catch((error) => {
  console.error(`❌ ${error.message}`);
  process.exitCode = 1;
});

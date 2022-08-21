# Transito

Transito is a bus timing app that users can use to view the bus arrival timings while interacting with an aesthetically pleasing and minimal user interface

The app was built with ease of access in mind to enable users to get information swiftly. Features included in this app were also carefully curated to improve the user's quality of life without making the app feel bloated and confusing to use.

One such feature is the "At a glance" screen. It allows users to instantly see the timings of certain buses at favourited bus stops instead of searching and sifting through the list of nearby bus stops.

## Built using

This app is built using the Flutter Framework made by Google. It also uses Firebase and Firestore for authentication and as a database respectively

Bus arrival data is provided via [Singapore's Land Transport Authority's DataMall Datasets](https://datamall.lta.gov.sg/content/datamall/en.html)

Map Tiles used are from [OneMap's Night Layout](https://www.onemap.gov.sg/docs/maps/night.html)

### Packages used
* ### Flutter SDK
	* [provider](https://pub.dev/packages/provider)
	* [http](https://pub.dev/packages/http)
	* [json_serializable](https://pub.dev/packages/json_serializable)
* ### Firebase
	* [firebase Core](https://pub.dev/packages/firebase_core)
	* [firebase Auth](https://pub.dev/packages/firebase_auth)
	* [google_sign_in](https://pub.dev/packages/google_sign_in)
	* [cloud_firestore](https://pub.dev/packages/cloud_firestore)
* ### Location
	* [geolocator](https://pub.dev/packages/geolocator)
	* [latlong2](https://pub.dev/packages/latlong2)
	* [flutter_map](https://pub.dev/packages/flutter_map)
* ### Froms
	* [flutter_form_builder](https://pub.dev/packages/flutter_form_builder)
	* [form_builder_validators](https://pub.dev/packages/form_builder_validators)
	* [form_builder_extra_fields](https://pub.dev/packages/form_builder_extra_fields)
	* [parent_child_checkbox](https://pub.dev/packages/parent_child_checkbox)
		* [forked version](https://github.com/TechSupportz/parent-child-checkbox)
* ### Other Useful Stuff
	* WIP

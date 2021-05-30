import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lazyplants/components/db_models.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive/hive.dart';

import 'package:lazyplants/components/api_connector.dart';
import 'package:path_provider/path_provider.dart';
import 'unit_test.mocks.dart';

final client = MockClient();
final ApiConnector api = ApiConnector(client);

// Generate a MockClient using the Mockito package.
// Create new instances of this class in each test.
void clear() {
  api.dataBox.clear();
  api.plantBox.clear();
  api.settingsBox.clear();
}

@GenerateMocks([http.Client])
void main() async {
  Directory dir = await getApplicationDocumentsDirectory();
  //Datenbank laden
  Hive
    ..init(dir.path)
    ..registerAdapter(PlantAdapter())
    ..registerAdapter(PlantDataAdapter());

  // create apiConnector and init Boxes
  api.dataBox = await Hive.openBox('plantData');
  api.plantBox = await Hive.openBox('plants');
  api.settingsBox = await Hive.openBox('settings');
  api.settingsBox.put('token', "testToken");

  var baseUrl = 'https://api.kie.one/api/';
  group('GET', () {
    group('getExactPlantData', () {
      const int limit = 1;
      const String espId = "espBlume3";
      var uri = Uri.parse(baseUrl +
          "PlantData?access_token=" +
          api.settingsBox.get('token') +
          "&filter[order]=date%20DESC&filter[limit]=" + limit.toString() + "&filter[espId]=" + espId);
      test('getexactPlantData successful', () async {
        print("Test: getData, working");
        print(uri);
        var response =
            '{"espId": "espBlume3","soilMoisture": 26,"humidity": 41,"temperature": 24.4,"watertank": 36,"water": false,"measuringTime": "2021-03-05T13:43:46.000Z","id": "6042278d701e762c3a840970","plantsId": "5fcf98e9f106a01bbacc5a79","memberId": "5fbd47595421905a1a869a55"}';
        // mock the api request
        when(client.get(uri))
            .thenAnswer((_) async => http.Response(response, 200));
        var data = await api.getExactPlantData(limit, espId);
        expect(data, jsonDecode(response));
        //clear();
      });
      test('getExactPlantData with exception', () async {
        print("Test: getExactPlantData, error");
        var response = 'error';
        // mock the api request
        when(client.get(uri))
            .thenAnswer((_) async => http.Response(response, 401));
        var data = await api.getExactPlantData(limit, espId);
        expect(data, "error");
        //clear();
      });
    });

    group('getPlant', () {
      var uri = Uri.parse(
          baseUrl + "Plants?access_token=" + api.settingsBox.get('token'));
      test('getPlant successful', () async {
        print("Test: getPlant, working");
        var response =
            '{"plantName": "Pflanze 1","plantDate": "2020-12-08T08:02:32.084Z","espId": "espBlume4","soilMoisture": 45,"humidity": 30,"id": "5fcf34c5e4f580d626f63922","memberId": "5fbd47795421905a1a869a56"}';
        // mock the api request
        when(client.get(uri))
            .thenAnswer((_) async => http.Response(response, 200));
        var data = await api.getPlant();
        expect(data, jsonDecode(response));
      });
      test('getPlant with exception', () async {
        print("Test: getPlant, error");
        var response = 'error';
        // mock the api request
        when(client.get(uri))
            .thenAnswer((_) async => http.Response(response, 401));
        var data = await api.getPlant();
        expect(data, "error");
      });
    });

    group('getMembersData', () {
      var userId = "1234";
      var uri = Uri.parse(baseUrl +
          "Members/" +
          userId +
          "?access_token=" +
          api.settingsBox.get('token'));
      test('getMembersData successful', () async {
        print("Test: getMembersData, working");
        var response =
            '{"firstname": "Max","lastname": "Mustermann","memberPic": {},"realm": "string","username": "max123","email": "max@max.com","emailVerified": false,"id": "606600e9701e762c3a8418f0"}';
        // mock the api request
        when(client.get(uri))
            .thenAnswer((_) async => http.Response(response, 200));
        var data = await api.getMembersData();
        expect(data, 0);
        expect(api.settingsBox.get('firstName'), "Max");
        expect(api.settingsBox.get('lastName'), "Mustermann");
      });
      test('getMembersData with exception', () async {
        print("Test: getMembersData, error");
        var response = 'error';
        // mock the api request
        when(client.get(uri))
            .thenAnswer((_) async => http.Response(response, 401));
        var data = await api.getMembersData();
        expect(data, 1);
      });

      test('getMembersData with other Statuscode', () async {
        print("Test: getMembersData, other Statuscode");
        var response = 'error';
        // mock the api request
        when(client.get(uri))
            .thenAnswer((_) async => http.Response(response, 501));
        var data = await api.getMembersData();
        expect(data, 1);
      });
    });
  }); //GET

  group('PATCH', () {
    group('patchPlant', () {
      var uri = Uri.parse(
          baseUrl + "Plants?access_token=" + api.settingsBox.get('token'));
      var plantId = "5fc76bf50b487e3b0415f56d";
      var espName = "espBlume3";
      var plantName = "TEST";
      var room = "t";
      var soilMoisture = "25.0";
      var memberId = "5fbd47595421905a1a869a55";

      test('patchPlant successful', () async {
        print("Test: patchPlant, working");
        var response =
            '{"plantName": "TEST","plantDate": "2020-12-02T09:29:16.519Z","espId": "espBlume3","soilMoisture": 25,"humidity": 30,"id": "5fc76bf50b487e3b0415f56d","memberId": "5fbd47595421905a1a869a55"}';
        // mock the api request
        when(client.patch(uri, body: {
          "plantName": plantName,
          "espName": espName,
          "id": plantId,
          "soilMoisture": soilMoisture,
          "memberId": memberId
        })).thenAnswer((_) async => http.Response(response, 200));
        var data = await api.patchPlant(
            plantId, plantName, espName, room, soilMoisture, memberId);
        expect(data, jsonDecode(response));
      });

      test('patchPlant with exception', () async {
        print("Test: patchPlant, error");
        var response = 'error';
        // mock the api request
        when(client.patch(uri, body: {
          "plantName": plantName,
          "espId": espName,
          "id": plantId,
          "soilMoisture": soilMoisture,
          "memberId": memberId
        })).thenAnswer((_) async => http.Response(response, 401));
        var data = await api.patchPlant(
            plantId, plantName, espName, room, soilMoisture, memberId);
        expect(data, 401);
      });

      test('patchPlant with other Statuscode', () async {
        print("Test: patchPlant, other Statuscode");
        var response = 'error';
        // mock the api request
        when(client.patch(uri, body: {
          "plantName": plantName,
          "espName": espName,
          "id": plantId,
          "soilMoisture": soilMoisture,
          "memberId": memberId
        })).thenAnswer((_) async => http.Response(response, 501));
        var data = await api.patchPlant(
            plantId, plantName, espName, room, soilMoisture, memberId);
        expect(data, "error");
      });
    }); //patchPlant
  }); //PATCH

  group('POST', () {
    group('postLogin', () {
      //TODO: Fehler zugriff auf Hive DB
      var mail = "max@max.com";
      var pw = "max123";
      var uri = Uri.parse(baseUrl + "Members/login");
      var token = "POST_TOKEN";
      var userId = "userId";
      var t = api.settingsBox.get('token');

      test('postLogin successful', () async {
        print("Test: postLogin, working");
        var response = '{"id": "' +
            token +
            '","ttl": 1209600,"created": "2021-05-10T17:35:49.490Z","userId": "' +
            userId +
            '"}';
        // mock the api request
        when(client.post(uri, body: {"email": mail, "password": pw}))
            .thenAnswer((_) async => http.Response(response, 200));
        expect(await api.postLogin(mail, pw), 0);
        expect(api.settingsBox.get('token'), token);
        api.settingsBox.put('token', t);
        expect(api.settingsBox.get('userId'), userId);
      });

      test('postLogin with exception', () async {
        print("Test: postLogin, error");
        var response = 'error';
        // mock the api request
        when(client.post(uri, body: {"email": mail, "password": pw}))
            .thenAnswer((_) async => http.Response(response, 401));
        expect(await api.postLogin(mail, pw), 1);
        expect(api.settingsBox.get('token'), t);
      });
    }); //postLogin

    group('postCreateAccount', () {
      var uri = Uri.parse(baseUrl + "Members");
      var uriLogin = Uri.parse(baseUrl + "Members/login");
      var firstName = "Reiner";
      var lastName = "Zufall";
      var username = "Reinerzufall";
      var mail = "r@zufall.de";
      var password = "passwort";
      var userId = "id";
      var token = api.settingsBox.get('token');
      var responseSuccsess = '{"firstname": "' +
          firstName +
          '","lastname": "' +
          lastName +
          '","username": "' +
          username +
          '","email": "' +
          mail +
          '","id": "' +
          userId +
          '"}';
      var responseLogin = '{"id": "' +
          token +
          '","ttl": 1209600,"created": "2021-05-10T17:35:49.490Z","userId": "' +
          userId +
          '"}';
      test('postCreateAccount successful', () async {
        print("Test: postCreateAccount, working");
        // mock the api request
        when(client.post(uri, body: {
          "firstname": firstName,
          "lastname": lastName,
          "username": username,
          "email": mail,
          "password": password
        })).thenAnswer((_) async => http.Response(responseSuccsess, 200));
        when(client.post(uriLogin, body: {"email": mail, "password": password}))
            .thenAnswer((_) async => http.Response(responseLogin, 200));
        expect(
            await api.postCreateAccount(
                firstName, lastName, username, mail, password),
            0);
        expect(api.settingsBox.get('userId'), userId);
        expect(api.settingsBox.get('firstName'), firstName);
        expect(api.settingsBox.get('lastName'), lastName);
        expect(api.settingsBox.get('token'), token);
        expect(api.settingsBox.get('userId'), userId);
      });

      test('postCreateAccount with exist Account', () async {
        print("Test: postCreateAccount, exist Account");
        var response = 'error';
        var token = api.settingsBox.get('token');
        // mock the api request
        when(client.post(uri, body: {
          "firstname": firstName,
          "lastname": lastName,
          "username": username,
          "email": mail,
          "password": password
        })).thenAnswer((_) async => http.Response(responseSuccsess, 200));

        when(client.post(uriLogin, body: {"email": mail, "password": password}))
            .thenAnswer((_) async => http.Response(response, 401));
        expect(
            await api.postCreateAccount(
                firstName, lastName, username, mail, password),
            4);
        expect(api.settingsBox.get('token'), token);
        expect(api.settingsBox.get('userId'), userId);
        expect(api.settingsBox.get('firstName'), firstName);
        expect(api.settingsBox.get('lastName'), lastName);
      });

      test('postCreateAccount with exist Email', () async {
        print("Test: postCreateAccount, error");
        var response = '{"error":' +
            '{"details":' +
            '{"messages":' +
            '{"email":[' +
            '"Email already exists"]}}}}';
        print(response);
        // mock the api request
        when(client.post(uri, body: {
          "firstname": firstName,
          "lastname": lastName,
          "username": username,
          "email": mail,
          "password": password
        })).thenAnswer((_) async => http.Response(response, 422));
        expect(
            await api.postCreateAccount(
                firstName, lastName, username, mail, password),
            2);
      });

      test('postCreateAccount with exist Username', () async {
        print("Test: postCreateAccount, error");
        var response = '{"error":' +
            '{"details":' +
            '{"messages":' +
            '{"username":[' +
            '"User already exists"]}}}}'; // mock the api request
        when(client.post(uri, body: {
          "firstname": firstName,
          "lastname": lastName,
          "username": username,
          "email": mail,
          "password": password
        })).thenAnswer((_) async => http.Response(response, 422));
        expect(
            await api.postCreateAccount(
                firstName, lastName, username, mail, password),
            3);
      });
      test('postCreateAccount with exist Username & Email', () async {
        print("Test: postCreateAccount, error");
        var response = '{"error":' +
            '{"details":' +
            '{"messages":' +
            '{"username":["User already exists"],' +
            '"email":["Email already exists"]' +
            '}}}}'; // mock the api request
        when(client.post(uri, body: {
          "firstname": firstName,
          "lastname": lastName,
          "username": username,
          "email": mail,
          "password": password
        })).thenAnswer((_) async => http.Response(response, 422));
        expect(
            await api.postCreateAccount(
                firstName, lastName, username, mail, password),
            1);
      });
      test('postCreateAccount with exception', () async {
        print("Test: postCreateAccount, error");
        var response = "error";
        api.settingsBox.put('userId', null);
        api.settingsBox.put('firstName', null);
        api.settingsBox.put('lastName', null);
        // mock the api request
        when(client.post(uri, body: {
          "firstname": firstName,
          "lastname": lastName,
          "username": username,
          "email": mail,
          "password": password
        })).thenAnswer((_) async => http.Response(response, 501));
        expect(
            await api.postCreateAccount(
                firstName, lastName, username, mail, password),
            4);
        expect(api.settingsBox.get('userId'), null);
        expect(api.settingsBox.get('firstName'), null);
        expect(api.settingsBox.get('lastName'), null);
      });
    }); //postCreateAccount
  }); //POST

  test('checkLoggedIn', () {
    print("Test: checkLoggedIn");
    api.settingsBox.put('token', null);
    expect(api.checkLoggedIn(), false);
    api.settingsBox.put('token', "test");
    expect(api.checkLoggedIn(), true);
  });
} //main

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/authorization_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

void main() async {
  await DotEnv().load('.env');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Github OAuth2 Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Github OAuth2 Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String githubClientId = DotEnv().env['GITHUB_CLIENT_ID'];
  // NEVER STORE THE CLIENT SECRET ON THE APP,
  // move the responsibility to the backend get you the access token
  String githubClientSecret = DotEnv().env['GITHUB_CLIENT_SECRET'];
  String gitlabClientId = DotEnv().env['GITLAB_CLIENT_ID'];
  String gitlabClientSecret = DotEnv().env['GITLAB_CLIENT_SECRET'];
  String codeVerifier = Uuid().v4() + Uuid().v4();

  Future<void> authenticate() async {
    try {
      OAuth2Client client = OAuth2Client(
        authorizeUrl: 'https://github.com/login/oauth/authorize',
        tokenUrl: 'https://github.com/login/oauth/access_token',
        redirectUri: 'dev.lucaswilliameufrasio.flutteroauth://oauth2redirect',
        customUriScheme: 'dev.lucaswilliameufrasio.flutteroauth',
      );
      client.accessTokenRequestHeaders = {'Accept': 'application/json'};

      await client.getTokenWithAuthCodeFlow(
        clientId: githubClientId,
        scopes: ['identity'],
        afterAuthorizationCodeCb: getGithubAccessToken,
      );
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> getGithubAccessToken(
      AuthorizationResponse authorizationResponse) async {
    print(authorizationResponse.code);

    // This need to be responsibility of backend
    // send the code (authorizationResponse.code) to the backend
    var params = {
      "code": authorizationResponse.code,
      "client_id": githubClientId,
      "client_secret": githubClientSecret
    };
    var uri = Uri.https('github.com', 'login/oauth/access_token', params);
    var accessToken = await http.post(uri);
    print(accessToken.body);
  }

  Future<void> authenticateToGitlab() async {
    var codeChallenge = base64Url
        .encode(sha256.convert(utf8.encode(codeVerifier)).bytes)
        .replaceAll("=", "")
        .replaceAll("+", "-")
        .replaceAll("/", "_");
    ;
    try {
      OAuth2Client client = OAuth2Client(
        authorizeUrl: 'https://gitlab.com/oauth/authorize',
        tokenUrl: '',
        redirectUri: 'dev.lucaswilliameufrasio.flutteroauth://oauth2redirect',
        customUriScheme: 'dev.lucaswilliameufrasio.flutteroauth',
      );
      print(client.redirectUri);

      var accessToken = await client.getTokenWithAuthCodeFlow(
        clientId: gitlabClientId,
        authCodeParams: {
          "code_challenge": codeChallenge,
          "code_challenge_method": "S256",
        },
        scopes: ['read_user'],
        afterAuthorizationCodeCb: getGitlabAccessToken,
      );
      print(accessToken);
      // print(codeChallenge);
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> getGitlabAccessToken(
      AuthorizationResponse authorizationResponse) async {
    print(authorizationResponse.code);
    // print(codeVerifier);

    // This need to be responsibility of backend
    // send the code (authorizationResponse.code) to the backend
    var params = {
      "client_id": gitlabClientId,
      "client_secret": gitlabClientSecret,
      "code": authorizationResponse.code,
      "grant_type": "authorization_code",
      "redirect_uri": "dev.lucaswilliameufrasio.flutteroauth://oauth2redirect",
      "code_verifier": codeVerifier
    };
    var uri = Uri.https('gitlab.com', '/oauth/token', params);
    var accessToken = await http.post(uri);
    print(accessToken.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Press the button to authenticate:',
            ),
            RaisedButton(
              padding: const EdgeInsets.all(0.0),
              textColor: Colors.white,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2),
                      Color(0xFF42A5F5),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(10.0),
                child:
                    const Text('Authenticate', style: TextStyle(fontSize: 20)),
              ),
              onPressed: authenticate,
            ),
            RaisedButton(
              padding: const EdgeInsets.all(0.0),
              textColor: Colors.white,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2),
                      Color(0xFF42A5F5),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(10.0),
                child: const Text('Authenticate to Gitlab',
                    style: TextStyle(fontSize: 20)),
              ),
              onPressed: authenticateToGitlab,
            ),
          ],
        ),
      ),
    );
  }
}

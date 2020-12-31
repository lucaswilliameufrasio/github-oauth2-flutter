import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/authorization_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:flutter_config/flutter_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required by FlutterConfig
  await FlutterConfig.loadEnvVariables();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  String clientId = FlutterConfig.get('GITHUB_CLIENT_ID');
  // NEVER STORE THE CLIENT SECRET ON THE APP, 
  // move the responsibility to the backend get you the access token
  String clientSecret = FlutterConfig.get('GITHUB_CLIENT_SECRET');

  Future<void> authenticate() async {
    try {
      OAuth2Client aclient = OAuth2Client(
        authorizeUrl: 'https://github.com/login/oauth/authorize',
        tokenUrl: 'https://github.com/login/oauth/access_token',
        redirectUri: 'dev.lucaswilliameufrasio.flutteroauth://oauth2redirect',
        customUriScheme: 'dev.lucaswilliameufrasio.flutteroauth',
      );
      aclient.accessTokenRequestHeaders = {'Accept': 'application/json'};

      await aclient.getTokenWithAuthCodeFlow(
        clientId: clientId,
        scopes: ['identity'],
        afterAuthorizationCodeCb: getAccessToken,
      );
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> getAccessToken(
      AuthorizationResponse authorizationResponse) async {
    print(authorizationResponse.code);

    // This need to be responsibility of backend
    // send the code (authorizationResponse.code) to the backend
    var params = {
      "code": authorizationResponse.code,
      "client_id": clientId,
      "client_secret": clientSecret
    };
    var uri = Uri.https('github.com', 'login/oauth/access_token', params);
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
            )
          ],
        ),
      ),
    );
  }
}

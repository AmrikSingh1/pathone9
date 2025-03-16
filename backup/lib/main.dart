import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'membership_selection.dart';
import 'homepage.dart';

// Add a utility class for responsive design
class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double textScaleFactor;
  static late bool isSmallScreen;
  static late bool isMediumScreen;
  static late bool isLargeScreen;
  static late Orientation orientation;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;
    textScaleFactor = _mediaQueryData.textScaleFactor;
    
    // Block sizes for responsive calculations
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    
    // Safe area values
    _safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
    
    // Screen size categories
    isSmallScreen = screenHeight < 700;
    isMediumScreen = screenHeight >= 700 && screenHeight < 900;
    isLargeScreen = screenHeight >= 900;
  }
}

// Create a responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, SizeConfig config) builder;

  const ResponsiveBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return builder(context, SizeConfig());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PathOne',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Apply a global text scale factor to ensure text is readable on all devices
        final mediaQuery = MediaQuery.of(context);
        final constrainedTextScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);
        
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaleFactor: constrainedTextScaleFactor,
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Primary blue color
          secondary: const Color(0xFF3B82F6),
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Inter'),
          displayMedium: TextStyle(fontFamily: 'Inter'),
          displaySmall: TextStyle(fontFamily: 'Inter'),
          headlineLarge: TextStyle(fontFamily: 'Inter'),
          headlineMedium: TextStyle(fontFamily: 'Inter'),
          headlineSmall: TextStyle(fontFamily: 'Inter'),
          titleLarge: TextStyle(fontFamily: 'Inter'),
          titleMedium: TextStyle(fontFamily: 'Inter'),
          titleSmall: TextStyle(fontFamily: 'Inter'),
          bodyLarge: TextStyle(fontFamily: 'Inter'),
          bodyMedium: TextStyle(fontFamily: 'Inter'),
          bodySmall: TextStyle(fontFamily: 'Inter'),
          labelLarge: TextStyle(fontFamily: 'Inter'),
          labelMedium: TextStyle(fontFamily: 'Inter'),
          labelSmall: TextStyle(fontFamily: 'Inter'),
        ),
      ),
      initialRoute: _determineInitialRoute(),
      onGenerateRoute: (settings) {
        // Extract route parameters
        final uri = Uri.parse(settings.name ?? '');
        final queryParams = uri.queryParameters;
        final isFirstLaunch = queryParams['isFirstLaunch'] == 'true';
        final isSignUp = queryParams['isSignUp'] == 'true';
        final showLoginContent = queryParams['showLoginContent'] == 'true';
        
        // Save onboarding status when user starts the login process
        if (uri.path == '/login') {
          prefs.setBool('has_started_onboarding', true);
        }
        
        // Handle routes
        switch (uri.path) {
          case '/login':
            return MaterialPageRoute(
              builder: (context) => LoginPage(
                isFirstLaunch: isFirstLaunch,
                isSignUp: isSignUp,
                showLoginContent: showLoginContent,
              ),
            );
          case '/membership':
            return MaterialPageRoute(
              builder: (context) => MembershipSelectionPage(
                userId: settings.arguments != null && settings.arguments is Map<String, dynamic>
                    ? (settings.arguments as Map<String, dynamic>)['userId'] ?? prefs.getString('user_id') ?? 'unknown'
                    : prefs.getString('user_id') ?? 'unknown',
              ),
            );
          case '/homepage':
            return MaterialPageRoute(
              builder: (context) => const HomePage(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => LoginPage(
                isFirstLaunch: isFirstLaunch,
                isSignUp: isSignUp,
                showLoginContent: showLoginContent,
              ),
            );
        }
      },
    );
  }

  String _determineInitialRoute() {
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    final hasStartedOnboarding = prefs.getBool('has_started_onboarding') ?? false;
    final userId = prefs.getString('user_id');
    final hasMembership = prefs.getBool('has_membership') ?? false;

    // Set is_first_launch to false after the first launch
    if (isFirstLaunch) {
      prefs.setBool('is_first_launch', false);
    }

    // If user is logged in and has selected a membership, go to homepage
    if (userId != null && hasMembership) {
      return '/homepage';
    }
    
    // If user is logged in but hasn't selected a membership, go to membership selection
    if (userId != null && !hasMembership) {
      return '/membership';
    }
    
    // If user has started onboarding but not completed login, return to login page
    if (hasStartedOnboarding) {
      return '/login?showLoginContent=true';
    }
    
    // Otherwise, show the initial login page with options
    return isFirstLaunch ? '/login?isFirstLaunch=true' : '/login';
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

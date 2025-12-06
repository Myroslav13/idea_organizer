import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/notes_bloc.dart';
import 'models/note_model.dart';
import 'repositories/notes_repository.dart';
import 'widgets/other_widgets.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC8l_K1rz3nPoWfGtaQIrSxGZmNzvNrvNg",
        appId: "1:653289926049:web:be127cf6bfcfb6d5572fe0",
        messagingSenderId: "653289926049",
        projectId: "idea-organizer-afc78",
      ),
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Idea Organizer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(title: 'Idea Organizer'),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              // Створюємо репозиторій
              final notesRepository = FirestoreNotesRepository();

              // Передаємо його в BLoC
              return BlocProvider(
                create: (context) => NotesBloc(notesRepository: notesRepository)..add(LoadNotes()),
                child: const MainPage(),
              );
            },
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Try again later.';
          break;
        case 'network-request-failed':
          message = 'No internet connection. Please check your network.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password sign-in is disabled in Firebase.';
          break;
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        default:
          message = 'Login failed: ${e.message ?? 'Please try again.'}';
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _turnToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC3CFE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC3CFE2),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(height: 90),
            Text(
              'Idea Organizer',
              style: TextStyle(fontSize: 40, color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 378,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 270,
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: const TextStyle(fontSize: 20, fontFamily: 'Inter', color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: 270,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(fontSize: 20, fontFamily: 'Inter', color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 23),
                          SizedBox(
                            width: 270,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007BFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text(
                                'Login',
                                style: TextStyle(fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _turnToRegistration,
                style: TextButton.styleFrom(
                  overlayColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  "Are you not registered yet?",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Inter",
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              // Створюємо репозиторій
              final notesRepository = FirestoreNotesRepository();

              // Передаємо його в BLoC
              return BlocProvider(
                create: (context) => NotesBloc(notesRepository: notesRepository)..add(LoadNotes()),
                child: const MainPage(),
              );
            },
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth Error Code: ${e.code}');

      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'A user with this email already exists.';
          break;
        case 'weak-password':
          message = 'The password is too weak (min. 6 characters).';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password registration is disabled in Firebase.';
          break;
        default:
          message = 'Registration error. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown error. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC3CFE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC3CFE2),
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 90),
            Text(
              'Idea Organizer',
              style: TextStyle(fontSize: 40, color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 378,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Register', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 270,
                            child: TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                labelStyle: TextStyle(fontSize: 20, fontFamily: 'Inter', color: Colors.grey),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter your full name';
                                if (v.trim().split(' ').length < 2) return 'Enter your first name and last name';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 270,
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(fontSize: 20, fontFamily: 'Inter', color: Colors.grey),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter email';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Wrong email';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: 270,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(fontSize: 20, fontFamily: 'Inter', color: Colors.grey),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter password';
                                if (v.length < 6) return 'Password must contain 6 or more characters';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 23),
                          SizedBox(
                            width: 270,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007BFF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Register', style: TextStyle(fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class MainPage extends StatelessWidget {
  const MainPage({super.key});

  void _openNoteDialog(BuildContext context, Note? noteToEdit) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<NotesBloc>(context),
          child: NoteFormDialog(noteToEdit: noteToEdit),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC3CFE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC3CFE2),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
          child: Text(
            'Idea Organizer',
            style: TextStyle(
              fontSize: 40,
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
            child: SizedBox(
              height: 50,
              child: SearchBar(
                hintText: 'Search...',
                leading: const Icon(Icons.search, color: Colors.grey),
                backgroundColor: const MaterialStatePropertyAll<Color>(Color(0xFFFFFFFF)),
                shape: MaterialStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),

                onChanged: (value) {
                  context.read<NotesBloc>().add(FilterBySearch(value));
                },
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
        child: BlocBuilder<NotesBloc, NotesState>(
          builder: (context, state) {
            final List<String> tagNames = state.tagCounts.keys.toList()..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  child: Card(
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: tagNames.isEmpty
                        ? const Center(child: Text("No tags found yet."))
                        : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 0.0),
                      itemCount: tagNames.length,
                      itemBuilder: (context, index) {
                        final tagName = tagNames[index];
                        final tagCount = state.tagCounts[tagName] ?? 0;
                        final int colorAsInt = getColorForTag(tagName);
                        final String tagColor = "0x${colorAsInt.toRadixString(16)}";
                        String displayTitle = tagName.replaceAll('#', '');
                        if (displayTitle.isNotEmpty) {
                          displayTitle = displayTitle[0].toUpperCase() + displayTitle.substring(1);
                        }

                        return buildListItem(
                          context,
                          color: tagColor,
                          title: displayTitle,
                          number: tagCount,
                          isSelected: state.selectedTag == tagName,
                          onTap: () {
                            context.read<NotesBloc>().add(FilterByTag(tagName));
                          },
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider(height: 1);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Stack(
                    children: [
                      Card(
                        elevation: 4,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: () {
                            if (state is NotesLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (state is NotesError) {
                              return Center(
                                child: Text(
                                  'Failed to load notes: ${state.message}',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            if (state.allNotes.isEmpty) {
                              return const Center(
                                child: Text('No notes found. Add one!'),
                              );
                            }

                            if (state.displayedNotes.isEmpty) {
                              return const Center(
                                child: Text('No notes match your filters.'),
                              );
                            }

                            return SingleChildScrollView(
                              child: Wrap(
                                spacing: 16.0,
                                runSpacing: 16.0,
                                alignment: WrapAlignment.start,
                                children: state.displayedNotes.map((note) {
                                  return GestureDetector(
                                    onTap: () {
                                      _openNoteDialog(context, note);
                                    },
                                    child: buildContentBlock(
                                      title: note.title,
                                      tags: note.tags,
                                      tagsColors: note.tagsColors,
                                      lastChange: note.lastChange,
                                      content: note.content,
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }(),
                        ),
                      ),
                      Positioned(
                        right: 35.0,
                        bottom: 35.0,
                        child: FloatingActionButton(
                          onPressed: () {
                            _openNoteDialog(context, null);
                          },
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
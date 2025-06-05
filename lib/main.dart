import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClickNum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NumberGamePage(),
    );
  }
}

class NumberGamePage extends StatefulWidget {
  const NumberGamePage({super.key});

  @override
  State<NumberGamePage> createState() => _NumberGamePageState();
}

class _NumberGamePageState extends State<NumberGamePage> {
  int level = 1;
  int current = 1;
  bool gameEnded = false;
  int secondsLeft = 5;
  Timer? timer;
  List<int> numbers = [];
  Set<int> completedLevels = {};
  Map<int, Offset> numberPositions = {};

  final double buttonSize = 60;
  final double spacing = 10;

  @override
  void initState() {
    super.initState();
    setupLevel();
  }

  void setupLevel() {
    timer?.cancel();
    int count = level + 4;
    numbers = List.generate(count, (i) => i + 1)..shuffle();
    numberPositions.clear();

    setState(() {
      current = 1;
      gameEnded = false;
      secondsLeft = 5 + level;
    });
  }

  void generatePositions(BoxConstraints constraints) {
    final rand = Random();
    final maxX = constraints.maxWidth - buttonSize;
    final maxY = constraints.maxHeight - buttonSize;
    final List<Offset> used = [];

    for (int number in numbers) {
      Offset pos;
      bool overlap;
      int tries = 0;

      do {
        pos = Offset(rand.nextDouble() * maxX, rand.nextDouble() * maxY);
        overlap = used.any((p) => (p - pos).distance < (buttonSize + spacing));
        tries++;
      } while (overlap && tries < 100);

      used.add(pos);
      numberPositions[number] = pos;
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        secondsLeft--;
        if (secondsLeft <= 0) {
          gameEnded = true;
          timer?.cancel();
          showEndDialog(false);
        }
      });
    });
  }

  void onNumberClick(int number) {
    if (gameEnded) return;

    if (number == current) {
      if (current == 1) startTimer();

      setState(() {
        current++;
        if (current > numbers.length) {
          gameEnded = true;
          timer?.cancel();
          completedLevels.add(level);
          showEndDialog(true);
        }
      });
    } else {
      gameEnded = true;
      timer?.cancel();
      showEndDialog(false);
    }
  }

  void showEndDialog(bool win) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(win ? 'Bravo !' : 'Perdu !'),
        content: Text(
          win
              ? 'Tu as fini le niveau $level en ${5 + level - secondsLeft} secondes !'
              : 'Tu as perdu. Réessaie !',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (win) level++;
              setupLevel();
            },
            child: Text(win ? 'Suivant' : 'Recommencer'),
          ),
        ],
      ),
    );
  }

  Color getButtonColor(int number) {
    if (number < current) return Colors.grey;
    return Colors.blue;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ClickNum - Niveau $level'),
        leading: IconButton(
          icon: const Icon(Icons.list),
          tooltip: 'Niveaux',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LevelSelectionPage(
                  currentLevel: level,
                  completedLevels: completedLevels,
                  onLevelSelected: (selectedLevel) {
                    setState(() {
                      level = selectedLevel;
                    });
                    setupLevel();
                  },
                ),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Text('Temps restant : $secondsLeft s',
              style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Text(
            gameEnded
                ? (current > numbers.length
                    ? 'Bravo !'
                    : 'Oups ! Mauvais numéro ou temps écoulé')
                : 'Clique les chiffres dans l’ordre !',
            style: const TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: level == 1
                  ? Center(
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: numbers.map((number) {
                          return SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: ElevatedButton(
                              onPressed: () => onNumberClick(number),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: getButtonColor(number),
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                '$number',
                                style: const TextStyle(
                                    fontSize: 20, color: Colors.white),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : LayoutBuilder(builder: (context, constraints) {
                      if (numberPositions.isEmpty) {
                        generatePositions(constraints);
                      }
                      return Stack(
                        children: numbers.map((number) {
                          final pos = numberPositions[number] ?? Offset.zero;
                          return Positioned(
                            left: pos.dx,
                            top: pos.dy,
                            child: SizedBox(
                              width: buttonSize,
                              height: buttonSize,
                              child: ElevatedButton(
                                onPressed: () => onNumberClick(number),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: getButtonColor(number),
                                  shape: const CircleBorder(),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  '$number',
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton(
              onPressed: setupLevel,
              child: const Text('Recommencer le niveau'),
            ),
          ),
        ],
      ),
    );
  }
}

class LevelSelectionPage extends StatelessWidget {
  final int currentLevel;
  final Set<int> completedLevels;
  final void Function(int) onLevelSelected;

  const LevelSelectionPage({
    super.key,
    required this.currentLevel,
    required this.completedLevels,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisis un niveau')),
      body: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: List.generate(20, (index) {
            final level = index + 1;
            final isCurrent = level == currentLevel;
            final isCompleted = completedLevels.contains(level);
            final isUnlocked =
                level == 1 || completedLevels.contains(level - 1);

            return ElevatedButton(
              onPressed: isUnlocked
                  ? () {
                      onLevelSelected(level);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent
                    ? Colors.blue
                    : (isCompleted ? Colors.green : Colors.grey.shade600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(60, 60),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$level',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  if (isCurrent)
                    const Icon(Icons.play_arrow, color: Colors.white, size: 16)
                  else if (isCompleted)
                    const Icon(Icons.check, color: Colors.white, size: 16)
                  else if (!isUnlocked)
                    const Icon(Icons.lock, color: Colors.white, size: 16),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

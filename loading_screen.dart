import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moelsee_final/reusable_widget/reusable.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _lineAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'MOELSEE',
                  style: GoogleFonts.montserrat(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF07E22),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 210,
                  width: 290,
                  child: moelseeLogo(),
                ),
              ],
            ),
            const SizedBox(height: 50),
            _buildModernLoadingLine(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLoadingLine() {
    return Container(
      width: 200,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: _lineAnimation.value * 50,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
          Positioned(
            left: -5,
            top: -7,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_lineAnimation.value * 170, 0),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

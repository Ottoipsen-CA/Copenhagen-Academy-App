import 'package:flutter/material.dart';

class SkillProgressBar extends StatelessWidget {
  final String skillName;
  final int currentValue;
  final int maxValue;
  final Color progressColor;
  final Color backgroundColor;
  final bool showPercentage;
  final bool showMaxValue;
  final double height;

  const SkillProgressBar({
    Key? key,
    required this.skillName,
    required this.currentValue,
    this.maxValue = 100,
    required this.progressColor,
    this.backgroundColor = const Color(0xFF173968),
    this.showPercentage = true,
    this.showMaxValue = true,
    this.height = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (currentValue / maxValue * 100).toInt();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skillName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Text(
                    currentValue.toString(),
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (showMaxValue)
                    Text(
                      '/$maxValue',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  if (showPercentage)
                    Text(
                      ' ($percentage%)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              // Background
              Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  color: backgroundColor,
                ),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: currentValue / maxValue,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    gradient: LinearGradient(
                      colors: [
                        progressColor.withOpacity(0.7),
                        progressColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // Level markers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (index) {
                    final markerValue = (maxValue / 5) * (index + 1);
                    final isReached = currentValue >= markerValue;
                    
                    return Container(
                      height: height,
                      width: 2,
                      color: isReached
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white.withOpacity(0.2),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Skill level indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLevelIndicator('Beginner', 0, 30),
              _buildLevelIndicator('Average', 30, 60),
              _buildLevelIndicator('Good', 60, 80),
              _buildLevelIndicator('Pro', 80, 95),
              _buildLevelIndicator('World Class', 95, 100),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLevelIndicator(String label, int min, int max) {
    final bool isCurrentLevel = currentValue >= min && currentValue < max;
    // Special case for max value
    if (max == 100 && currentValue == 100) {
      return Text(
        label,
        style: TextStyle(
          color: isCurrentLevel ? progressColor : Colors.transparent,
          fontSize: 10,
          fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }
    return Text(
      label,
      style: TextStyle(
        color: isCurrentLevel ? progressColor : Colors.transparent,
        fontSize: 10,
        fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
} 
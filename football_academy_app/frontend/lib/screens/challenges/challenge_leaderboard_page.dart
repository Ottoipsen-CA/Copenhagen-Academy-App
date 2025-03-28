import 'package:flutter/material.dart';
import '../../models/challenge.dart';

class ChallengeLeaderboardPage extends StatelessWidget {
  final Challenge challenge;

  const ChallengeLeaderboardPage({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0057),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0057), // Dark blue/purple
              Color(0xFF1C006C), // Mid purple
              Color(0xFF3D007A), // Lighter purple
            ],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Challenge header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: challenge.isActive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: challenge.isActive
                            ? Colors.green.withOpacity(0.5)
                            : Colors.red.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      challenge.isActive
                          ? challenge.timeRemaining
                          : 'Ended',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: challenge.isActive ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.participantCount} participants',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Podium if we have at least 3 entries
        if (challenge.leaderboard.length >= 3) _buildPodium(),
        
        const SizedBox(height: 24),
        
        // Full leaderboard
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'LEADERBOARD',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: challenge.leaderboard.length,
            itemBuilder: (context, index) {
              return _buildLeaderboardItem(
                challenge.leaderboard[index],
                index + 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodium() {
    // Get top 3 participants
    final first = challenge.leaderboard.isNotEmpty ? challenge.leaderboard[0] : null;
    final second = challenge.leaderboard.length > 1 ? challenge.leaderboard[1] : null;
    final third = challenge.leaderboard.length > 2 ? challenge.leaderboard[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (second != null)
            _buildPodiumItem(
              submission: second,
              place: 2,
              height: 80,
              isUser: challenge.userSubmission?.userId == second.userId,
            ),

          const SizedBox(width: 8),

          // 1st place
          if (first != null)
            _buildPodiumItem(
              submission: first,
              place: 1,
              height: 110,
              isUser: challenge.userSubmission?.userId == first.userId,
            ),

          const SizedBox(width: 8),

          // 3rd place
          if (third != null)
            _buildPodiumItem(
              submission: third,
              place: 3,
              height: 60,
              isUser: challenge.userSubmission?.userId == third.userId,
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required ChallengeSubmission submission,
    required int place,
    required double height,
    required bool isUser,
  }) {
    // Colors for each place
    final colors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };

    final color = colors[place]!;

    return Column(
      children: [
        // Profile picture with crown for 1st place
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                color: Colors.white.withOpacity(0.1),
                image: submission.userImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(submission.userImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: submission.userImageUrl == null
                  ? Center(
                      child: Text(
                        submission.userName.substring(0, 1),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    )
                  : null,
            ),
            if (place == 1)
              Positioned(
                top: -15,
                left: 0,
                right: 0,
                child: Icon(
                  Icons.emoji_events,
                  color: color,
                  size: 24,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Name
        SizedBox(
          width: 80,
          child: Text(
            submission.userName,
            style: TextStyle(
              color: isUser ? Colors.green : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              overflow: TextOverflow.ellipsis,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        // Score
        Text(
          submission.value.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Center(
            child: Text(
              place == 1 ? '1st' : place == 2 ? '2nd' : '3rd',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(ChallengeSubmission submission, int rank) {
    // Colors for each rank
    final rankColors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };

    final rankColor = rankColors[rank] ?? Colors.white.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: rankColor,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              image: submission.userImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(submission.userImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: submission.userImageUrl == null
                ? Center(
                    child: Text(
                      submission.userName.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatSubmissionDate(submission.submittedAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Text(
            '${submission.value}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSubmissionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 
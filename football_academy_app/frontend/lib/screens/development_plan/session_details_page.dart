import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_drawer.dart';

class WeeklyTrainingSchedulePage extends StatefulWidget {
  const WeeklyTrainingSchedulePage({Key? key}) : super(key: key);

  @override
  _WeeklyTrainingSchedulePageState createState() => _WeeklyTrainingSchedulePageState();
}

class _WeeklyTrainingSchedulePageState extends State<WeeklyTrainingSchedulePage> {
  int _currentWeek = 33; // Default to week 33
  final List<String> _months = ['JANUAR', 'FEBRUAR', 'MARTS', 'APRIL', 'MAJ', 'JUNI', 'JULI', 'AUGUST', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DECEMBER'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ugentlig Træningsplan', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B0057),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Week selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              color: const Color(0xFF0B0057).withOpacity(0.8),
              child: Row(
                children: [
                  // Week selector
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _currentWeek = _currentWeek > 1 ? _currentWeek - 1 : 52;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          'UGE $_currentWeek',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _currentWeek = _currentWeek < 52 ? _currentWeek + 1 : 1;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Placeholder to match layout
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Vertical list of days
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                itemCount: 7,
                itemBuilder: (context, index) => _buildDayCard(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(int dayIndex) {
    final dayNames = ['Mandag', 'Tirsdag', 'Onsdag', 'Torsdag', 'Fredag', 'Lørdag', 'Søndag'];
    final dates = ['15', '16', '17', '18', '19', '20', '21']; // Example dates for week 33
    
    // Mock training sessions data
    final sessions = [
      if (dayIndex == 0) 
        {'title': 'Teknik', 'time': '16:00 - 17:30', 'hasReflection': false},
      if (dayIndex == 2) 
        {'title': 'Taktik', 'time': '16:00 - 17:30', 'hasReflection': true},
      if (dayIndex == 4) 
        {'title': 'Kamp Forberedelse', 'time': '15:30 - 17:00', 'hasReflection': false},
      if (dayIndex == 5) 
        {'title': 'Kamp', 'time': '14:00 - 16:00', 'hasReflection': true},
    ];
    
    final hasSession = sessions.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF191E29).withOpacity(hasSession ? 0.9 : 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        collapsedBackgroundColor: hasSession 
            ? const Color(0xFF0B0057).withOpacity(0.8) 
            : const Color(0xFF191E29).withOpacity(0.8),
        backgroundColor: const Color(0xFF191E29),
        leading: CircleAvatar(
          backgroundColor: hasSession ? const Color(0xFF0B0057) : Colors.grey.shade700,
          child: Text(
            dates[dayIndex],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          dayNames[dayIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: hasSession
            ? _buildSessionIndicators(sessions)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                onPressed: () => _showAddTrainingDialog(selectedDay: dayIndex + 1),
                tooltip: 'Tilføj træning',
              ),
        children: [
          if (hasSession)
            ...sessions.map((session) => _buildSessionItem(session, dayIndex + 1)),
          if (!hasSession)
            ListTile(
              title: const Text(
                'Ingen træninger planlagt',
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              ),
              trailing: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('TILFØJ'),
                onPressed: () => _showAddTrainingDialog(selectedDay: dayIndex + 1),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionIndicators(List<Map<String, dynamic>> sessions) {
    final hasReflection = sessions.any((s) => s['hasReflection'] == true);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasReflection)
          const Icon(Icons.rate_review, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          '${sessions.length} ${sessions.length == 1 ? 'træning' : 'træninger'}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const Icon(Icons.expand_more, color: Colors.white70),
      ],
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session, int dayIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () => _showSessionDetails(context, session, dayIndex),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0057).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_run, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session['time'] as String,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (session['hasReflection'] as bool)
                const Tooltip(
                  message: 'Refleksioner tilføjet',
                  child: Icon(Icons.rate_review, size: 16, color: Colors.green),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.navigate_next, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTrainingDialog({int? selectedDay}) {
    final dayNames = ['Mandag', 'Tirsdag', 'Onsdag', 'Torsdag', 'Fredag', 'Lørdag', 'Søndag'];
    final dayText = selectedDay != null ? dayNames[selectedDay - 1] : 'Vælg dag';
    final dateText = selectedDay != null ? '${14 + selectedDay}. August' : '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191E29),
        title: Text('Tilføj Træning ${selectedDay != null ? "- $dayText" : ""}',
          style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedDay != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(dateText, style: const TextStyle(color: Colors.white70)),
                ),
              if (selectedDay == null)
                DropdownButtonFormField<int>(
                  dropdownColor: const Color(0xFF191E29),
                  decoration: const InputDecoration(
                    labelText: 'Vælg dag',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                  items: List.generate(7, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(
                        '${dayNames[index]} (${15 + index}. August)',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }),
                  onChanged: (value) {},
                ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tidspunkt',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Beskrivelse',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLER', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B0057),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Træning tilføjet')),
              );
            },
            child: const Text('GEM'),
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(BuildContext context, Map<String, dynamic> session, int day) {
    final dayNames = ['Mandag', 'Tirsdag', 'Onsdag', 'Torsdag', 'Fredag', 'Lørdag', 'Søndag'];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191E29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dayNames[day-1]}, ${14 + day}. August · ${session['time']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddTrainingDialog(selectedDay: day);
                      },
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 32),
                
                // Description section
                const Text(
                  'BESKRIVELSE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Teknikfokuseret træning med særligt fokus på pasninger og førsteberøringer. '
                  'Vi vil arbejde med forskellige øvelser i mindre grupper.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 24),
                
                // Reflections section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'REFLEKSIONER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (session['hasReflection'] as bool == false)
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('TILFØJ'),
                        onPressed: () => _showReflectionDialog(),
                        style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                session['hasReflection'] as bool
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Træningen gik godt i dag. Spillerne viste god fremgang med førsteberøringen. '
                            'Vi skal fortsætte med at arbejde på timing af løb og pasninger.',
                            style: TextStyle(color: Colors.white, height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'Tilføjet: 16. August',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                child: const Icon(Icons.edit, size: 16, color: Colors.white54),
                                onTap: () => _showReflectionDialog(isEdit: true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const Text(
                      'Ingen refleksioner tilføjet endnu',
                      style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                    ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('LUK'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReflectionDialog({bool isEdit = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191E29),
        title: Text(isEdit ? 'Rediger Refleksion' : 'Tilføj Refleksion',
          style: const TextStyle(color: Colors.white)),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Skriv dine tanker om træningen...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          controller: TextEditingController(
            text: isEdit ? 'Træningen gik godt i dag. Spillerne viste god fremgang med førsteberøringen. '
                  'Vi skal fortsætte med at arbejde på timing af løb og pasninger.' : '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULLER', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B0057),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEdit ? 'Refleksion opdateret' : 'Refleksion tilføjet')),
              );
            },
            child: const Text('GEM'),
          ),
        ],
      ),
    );
  }
} 
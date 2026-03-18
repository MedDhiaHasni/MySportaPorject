import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Sample data - just players and messages
  final List<Map<String, dynamic>> _chats = [
    {
      "name": "Karim Jaziri",
      "message": "Is the football court available tonight at 8pm?",
      "time": "18:24",
      "avatar": "KJ",
    },
    {
      "name": "Nadia Ben Salah",
      "message": "Can we extend our padel booking by 30 minutes?",
      "time": "17:10",
      "avatar": "NB",
    },
    {
      "name": "Mehdi Trabelsi",
      "message": "Thank you for confirming the reservation for tomorrow.",
      "time": "16:45",
      "avatar": "MT",
    },
    {
      "name": "Leila Mallouli",
      "message": "I need to reschedule my booking from 14:00 to 16:00",
      "time": "15:12",
      "avatar": "LM",
    },
    {
      "name": "Ahmed Ben Ali",
      "message": "Great session today! When can I book again?",
      "time": "14:30",
      "avatar": "AB",
    },
    {
      "name": "Sami Khelif",
      "message": "Is there parking available near the venue?",
      "time": "12:05",
      "avatar": "SK",
    },
  ];

  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    return _chats.where((chat) {
      return chat['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          chat['message'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: _filteredChats.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = _filteredChats[index];
                          return _buildPlayerChatTile(chat);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF001F20), Color(0xFF003D3E), kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.chat_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Messages",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${_chats.length} conversations',
                  style: const TextStyle(fontSize: 12, color: kTextMid),
                ),
              ],
            ),
          ),
          // New message button
          GestureDetector(
            onTap: () {
              // TODO: New message
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kTextDark,
          ),
          decoration: InputDecoration(
            hintText: "Search players...",
            hintStyle: const TextStyle(color: kTextLight, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: kTextLight,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerChatTile(Map<String, dynamic> chat) {
    return GestureDetector(
      onTap: () {
        // TODO: Open chat with player
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Player avatar with initials
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, kPrimary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    chat['avatar'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['name'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Text(
                          chat['time'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: kTextLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat['message'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: kTextMid),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: kPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No conversations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'No players matching "$_searchQuery"'
                : 'Your messages with players will appear here',
            style: TextStyle(fontSize: 13, color: kTextMid.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

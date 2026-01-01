import 'package:flutter/material.dart';
import 'package:dedikodu_app/core/theme/app_theme.dart';
import 'package:dedikodu_app/data/models/chat_room_model.dart';
import 'package:dedikodu_app/data/models/location_models.dart';
import 'package:dedikodu_app/data/repositories/chat_repository.dart';
import 'package:dedikodu_app/core/services/turkey_api_service.dart';
import 'package:dedikodu_app/features/chat/chat_room_screen.dart';

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  final _chatRepo = ChatRepository();
  final _turkeyApiService = TurkeyApiService();
  
  List<Province> _provinces = [];
  bool _isLoadingProvinces = true;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _initializeRooms();
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await _turkeyApiService.getProvinces();
      if (mounted) {
        setState(() {
          _provinces = provinces..sort((a, b) => a.name.compareTo(b.name));
          _isLoadingProvinces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProvinces = false);
      }
    }
  }

  Future<void> _initializeRooms() async {
    await _chatRepo.initializeDefaultRooms();
  }

  void _openChatRoom(ChatRoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(room: room),
      ),
    );
  }

  void _openCityChat(Province province) {
    final room = ChatRoomModel(
      id: 'city_${province.id}',
      name: '${province.name} Sohbet',
      type: 'city',
      cityId: province.id.toString(),
      cityName: province.name,
      createdAt: DateTime.now(),
    );

    // Create room if doesn't exist
    _chatRepo.createOrUpdateRoom(room);

    _openChatRoom(room);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbet Odaları'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General chat room
          _buildGeneralChatCard(),

          const SizedBox(height: 24),

          // City chat rooms header
          Row(
            children: [
              Icon(Icons.location_city, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Şehir Sohbetleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // City chat rooms list
          if (_isLoadingProvinces)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._provinces.map((province) => _buildCityChatCard(province)),
        ],
      ),
    );
  }

  Widget _buildGeneralChatCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Create general room directly
          final room = ChatRoomModel(
            id: 'general',
            name: 'Genel Sohbet',
            type: 'general',
            createdAt: DateTime.now(),
          );
          _openChatRoom(room);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.public,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Genel Sohbet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tüm Türkiye',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityChatCard(Province province) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openCityChat(province),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_city,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      province.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${province.name} sakinleri',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _turkeyApiService.dispose();
    super.dispose();
  }
}

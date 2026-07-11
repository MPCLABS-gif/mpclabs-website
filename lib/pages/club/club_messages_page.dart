import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/message_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/index.dart';

class ClubMessagesPage extends StatefulWidget {
  const ClubMessagesPage({super.key, required this.clubId});
  final String clubId;
  static String routeName = 'ClubMessagesPage';
  static String routePath = '/clubMessages';

  @override
  State<ClubMessagesPage> createState() => _ClubMessagesPageState();
}

class _ClubMessagesPageState extends State<ClubMessagesPage> {
  final _textController = TextEditingController();
  bool _pinned = false;
  bool _sending = false;

  bool get _isCoach {
    final accountType = currentUserDocument?.accountType ?? '';
    return accountType == 'coach' || accountType == 'headcoach' || accountType == 'headCoach';
  }

  @override
  void initState() {
    super.initState();
    if (!_isCoach) {
      MessageService().markAllAsRead(widget.clubId);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final coachName = currentUserDocument?.displayName ?? 'Coach';
      await MessageService().sendMessage(
        clubId: widget.clubId,
        text: text,
        coachName: coachName,
        pinned: _pinned,
      );
      _textController.clear();
      setState(() => _pinned = false);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Club Messages',
            style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: MessageService().streamMessages(widget.clubId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return Center(
                      child: Text('No messages yet. Send your first update to the club.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          textAlign: TextAlign.center),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final pinned = m['pinned'] as bool? ?? false;
                      final createdAt = m['createdAt'] as Timestamp?;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pinned ? primary.withOpacity(0.3) : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pinned)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.push_pin, size: 13, color: primary),
                                    const SizedBox(width: 4),
                                    Text('Pinned',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
                                  ],
                                ),
                              ),
                            Text(m['text'] ?? '',
                                style: TextStyle(fontSize: 14, color: FlutterFlowTheme.of(context).primaryText, height: 1.4)),
                            const SizedBox(height: 8),
                            Text(
                              createdAt != null ? _formatDate(createdAt.toDate()) : '',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_isCoach)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _pinned,
                          onChanged: (v) => setState(() => _pinned = v ?? false),
                          activeColor: primary,
                        ),
                        Text('Pin this message', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Message the club...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
                              : Icon(Icons.send, color: primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

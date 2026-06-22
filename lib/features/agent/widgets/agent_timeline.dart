import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sbiv2/core/theme/app_theme.dart';
import 'package:sbiv2/features/agent/models/timeline_entry.dart';

/// Reusable timeline widget.
///
/// Pass [maxEntries] to cap the number shown (e.g. 3 for the Home screen).
/// Leave null to show all entries (AI Chat screen).
class AgentTimeline extends StatelessWidget {
  final List<TimelineEntry> entries;
  final int? maxEntries;

  const AgentTimeline({
    super.key,
    required this.entries,
    this.maxEntries,
  });

  @override
  Widget build(BuildContext context) {
    final visible = maxEntries != null && entries.length > maxEntries!
        ? entries.sublist(0, maxEntries!)
        : entries;

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No agent actions yet.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: visible.map((e) => _TimelineRow(entry: e)).toList(),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineEntry entry;
  const _TimelineRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(entry.status);
    final icon = _typeIcon(entry.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon column with vertical connector line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _StatusChip(status: entry.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(entry.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(TimelineEntryStatus status) {
    switch (status) {
      case TimelineEntryStatus.success:
        return AppTheme.accentGreen;
      case TimelineEntryStatus.running:
        return AppTheme.aiTeal;
      case TimelineEntryStatus.failed:
        return Colors.red;
      case TimelineEntryStatus.info:
        return AppTheme.accentOrange;
    }
  }

  IconData _typeIcon(TimelineEntryType type) {
    switch (type) {
      case TimelineEntryType.signalDetected:
        return Icons.radar;
      case TimelineEntryType.recommendation:
        return Icons.lightbulb_outline;
      case TimelineEntryType.toolStarted:
        return Icons.play_circle_outline;
      case TimelineEntryType.toolCompleted:
        return Icons.check_circle_outline;
      case TimelineEntryType.toolFailed:
        return Icons.error_outline;
      case TimelineEntryType.connection:
        return Icons.wifi;
      case TimelineEntryType.onboarding:
        return Icons.verified_user_outlined;
      case TimelineEntryType.insight:
        return Icons.insights;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final TimelineEntryStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case TimelineEntryStatus.success:
        color = AppTheme.accentGreen;
        label = 'Success';
        break;
      case TimelineEntryStatus.running:
        color = AppTheme.aiTeal;
        label = 'Running';
        break;
      case TimelineEntryStatus.failed:
        color = Colors.red;
        label = 'Failed';
        break;
      case TimelineEntryStatus.info:
        color = AppTheme.accentOrange;
        label = 'Info';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

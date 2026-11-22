import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../chat_texts.dart';
import '../models/chat_models.dart';

/// 사진(`image`) 및 동영상(`video`) 메시지 카드 위젯.
class MediaMessageCard extends StatelessWidget {
  const MediaMessageCard({
    super.key,
    required this.message,
    required this.maxWidth,
  });

  final ChatMessage message;
  final double maxWidth;

  bool get _isVideo => message.type == ChatMessageType.video;

  void _openPreview(BuildContext context) {
    final accent = message.mediaAccentColor ?? AppColors.primary;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: _isVideo ? 16 / 10 : 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _MediaVisualSurface(
                      mediaUrl: message.mediaUrl,
                      accentColor: accent,
                      isVideo: _isVideo,
                      title: message.mediaTitle,
                      large: true,
                    ),
                    if (_isVideo)
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.mediaTitle ??
                            (_isVideo
                                ? ChatTexts.previewVideoFallback
                                : ChatTexts.previewPhotoFallback),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isVideo && message.mediaDuration != null)
                      Text(
                        message.mediaDuration!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = message.mediaAccentColor ?? AppColors.primary;
    final cardWidth = maxWidth.clamp(160.0, 224.0);
    final cardHeight = _isVideo ? 156.0 : 210.0;

    return GestureDetector(
      onTap: () => _openPreview(context),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _MediaVisualSurface(
              mediaUrl: message.mediaUrl,
              accentColor: accent,
              isVideo: _isVideo,
              title: message.mediaTitle,
            ),
            // 동영상 중앙 재생(▶) 오버레이
            if (_isVideo)
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.56),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.8),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            // 하단 캡션 & 동영상 길이 뱃지
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 18, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.62),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.mediaTitle ??
                            (_isVideo
                                ? ChatTexts.mediaVideo
                                : ChatTexts.mediaPhoto),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_isVideo && message.mediaDuration != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message.mediaDuration!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 네트워크 이미지 또는 오프라인 안전 Mock 그래픽 카드 표면.
class _MediaVisualSurface extends StatelessWidget {
  const _MediaVisualSurface({
    required this.mediaUrl,
    required this.accentColor,
    required this.isVideo,
    this.title,
    this.large = false,
  });

  final String? mediaUrl;
  final Color accentColor;
  final bool isVideo;
  final String? title;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fallback = _MockMediaPlaceholder(
      accentColor: accentColor,
      isVideo: isVideo,
      large: large,
    );

    if (mediaUrl == null || mediaUrl!.isEmpty) {
      return fallback;
    }

    return Image.network(
      mediaUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return fallback;
      },
    );
  }
}

class _MockMediaPlaceholder extends StatelessWidget {
  const _MockMediaPlaceholder({
    required this.accentColor,
    required this.isVideo,
    this.large = false,
  });

  final Color accentColor;
  final bool isVideo;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.72),
            accentColor.withValues(alpha: 0.96),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: large ? 130 : 88,
              height: large ? 130 : 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: 12,
            child: Container(
              width: large ? 150 : 104,
              height: large ? 150 : 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          if (!isVideo)
            Center(
              child: Icon(
                Icons.photo_library_rounded,
                size: large ? 58 : 42,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
        ],
      ),
    );
  }
}

/// 답장 프리뷰 / 입력창 배너에서 사용하는 작은 미디어 썸네일 (40x40).
class MediaMiniThumbnail extends StatelessWidget {
  const MediaMiniThumbnail({
    super.key,
    required this.type,
    this.mediaUrl,
    this.accentColor,
    this.size = 42,
  });

  final ChatMessageType type;
  final String? mediaUrl;
  final Color? accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    final isVideo = type == ChatMessageType.video;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.75),
            color,
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mediaUrl != null && mediaUrl!.isNotEmpty)
            Image.network(
              mediaUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Center(
            child: Container(
              width: isVideo ? 22 : 24,
              height: isVideo ? 22 : 24,
              decoration: isVideo
                  ? BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                isVideo ? Icons.play_arrow_rounded : Icons.photo_rounded,
                size: isVideo ? 15 : 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

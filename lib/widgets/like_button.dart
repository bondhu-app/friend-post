import 'package:flutter/material.dart';

import '../services/like_service.dart';

class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.postId,
    this.showCount = true,
  });

  final String postId;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: LikeService.instance.likedStream(
        postId,
      ),
      builder: (context, likedSnapshot) {
        final isLiked =
            likedSnapshot.data ?? false;

        return StreamBuilder<int>(
          stream: LikeService.instance.likeCountStream(
            postId,
          ),
          builder: (context, countSnapshot) {
            final likeCount =
                countSnapshot.data ?? 0;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () async {
                    try {
                      await LikeService.instance
                          .toggleLike(
                        postId: postId,
                      );
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            _errorMessage(e),
                          ),
                        ),
                      );
                    }
                  },
                  tooltip: isLiked
                      ? 'Unlike'
                      : 'Like',
                  icon: Icon(
                    isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: isLiked
                        ? Colors.red
                        : null,
                  ),
                ),
                if (showCount)
                  Text(
                    likeCount.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _errorMessage(Object error) {
    final message = error.toString();

    if (message.contains(
      'Please login first',
    )) {
      return 'Please login first.';
    }

    if (message.contains(
      'Post not found',
    )) {
      return 'This post no longer exists.';
    }

    if (message.contains(
      'permission-denied',
    )) {
      return 'You do not have permission to like this post.';
    }

    return 'Could not update like. Please try again.';
  }
}

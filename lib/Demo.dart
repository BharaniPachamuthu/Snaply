import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'module_homescreen/message.dart';

class HomePages extends StatefulWidget {
  const HomePages({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePages> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController textcontroller = TextEditingController();
  final ScrollController scroll = ScrollController();

  final loading = false.obs;
  var postCommentVisibility = {}.obs;

  List<int> posts = [];
  List<String> images = [
    'https://cdn.pixabay.com/photo/2023/02/10/18/05/architecture-7781432_1280.jpg',
    'https://cdn.pixabay.com/photo/2016/03/30/08/24/peacock-1290248_1280.jpg',
    'https://cdn.pixabay.com/photo/2023/11/18/19/06/futuristic-home-8397004_1280.jpg',
    'https://cdn.pixabay.com/photo/2024/04/18/20/41/ai-generated-8705017_1280.png',
    'https://cdn.pixabay.com/photo/2023/12/19/22/46/heart-8458555_1280.jpg'
  ];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    FirebaseNotificationService().initialize();
    _initializeNotifications();
    scroll.addListener(() {
      if (scroll.position.pixels == scroll.position.maxScrollExtent) {
        if (shouldLoadMorePosts()) loadMorePost();
      }
    });
  }

  Future<void> getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('post').doc('postid')
          .update({'fcmToken': token});
    }
  }


  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);


    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
    print('User granted permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received a message in foreground: ${message.notification?.title}");
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened from background: ${message.notification?.title}");
      _showNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
  }

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.notification?.title}");
    await _showNotification(message);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    if (message.notification != null) {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'post', // Channel ID (must match the one set earlier)
        'postid',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title,
        message.notification?.body,
        platformDetails,
        payload: message.data.toString(), // Ensure correct payload structure
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [Expanded(child: _buildPostScreen())],
      ),
    );
  }

  Widget _buildPostScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('post').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No posts available'));
        }

        final posts = snapshot.data!.docs;

        return Obx(() {
          if (!loading.value && shouldLoadMorePosts()) {
            loadMorePost();
          }
          return ListView.builder(
            controller: scroll,
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index == posts.length) {
                return loading.value
                    ? const Center(
                        child: CircularProgressIndicator(
                        color: Colors.blue,
                      ))
                    : Container();
              } else {
                final post = posts[index].data() as Map<String, dynamic>;
                final postId = posts[index].id;
                return _buildPost(post, postId, index);
              }
            },
          );
        });
      },
    );
  }

  Widget _buildPost(Map<String, dynamic> post, String postId, int index) {
    final RxBool like = (post['like'] != null && post['like'] > 0).obs;
    final TextEditingController commentController = TextEditingController();

    if (!postCommentVisibility.containsKey(postId)) {
      postCommentVisibility[postId] = false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPostHeader(),
        CachedNetworkImage(
          imageUrl: post['image'] ?? ' ',
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildPostActions(post, postId, like, commentController),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Liked by bharani',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Obx(() => postCommentVisibility[postId]!
            ? _buildCommentsSection(postId)
            : const SizedBox()),
        Obx(() => postCommentVisibility[postId]!
            ? _buildCommentInput(postId, commentController)
            : const SizedBox()),
      ],
    );
  }

  Widget buildPostHeader() {
    return ListTile(
      leading: const CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(
            'https://cdn.pixabay.com/photo/2020/10/11/19/51/cat-5646889_1280.jpg'),
        backgroundColor: Colors.lightBlue,
      ),
      title: const Text(
        'Bharani',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '2 hour ago',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.more_vert_outlined),
      ),
    );
  }

  Widget _buildPostActions(Map<String, dynamic> post, String postId,
      RxBool like, TextEditingController commentController) {
    final int likeCount = post['like'] ?? 0;
    final int commentCount = post['comment'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Obx(
              () => IconButton(
                onPressed: () {
                  like.value = !like.value;
                  _updateLikeCount(postId, like.value, likeCount);
                },
                icon: like.value
                    ? const FaIcon(FontAwesomeIcons.solidHeart,
                        color: Colors.red)
                    : const FaIcon(FontAwesomeIcons.heart),
              ),
            ),
            Text('$likeCount',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () {
                postCommentVisibility[postId] = !postCommentVisibility[postId]!;
              },
              icon: const FaIcon(FontAwesomeIcons.comment),
            ),
            Text('$commentCount',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            IconButton(onPressed: () {}, icon: const Icon(Icons.send_outlined)),
            const Text('3'),
          ],
        ),
        IconButton(
            onPressed: () {}, icon: const Icon(Icons.bookmark_border_rounded)),
      ],
    );
  }

  Widget _buildCommentsSection(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('post')
          .doc(postId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('No comments yet'),
          );
        }

        final comments = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(comment['text'] ?? 'No text available'),
              subtitle: Text(comment['user'] ?? 'Anonymous'),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInput(String postId, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _submitComment(postId, controller.text.trim());
              controller.clear();
            },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _updateLikeCount(String postId, bool liked, int currentLikes) {
    final int newLikeCount = liked ? currentLikes + 1 : currentLikes - 1;
    _firestore.collection('post').doc(postId).update({
      'like': newLikeCount,
    });
  }

  void _submitComment(String postId, String commentText) {
    if (commentText.isNotEmpty) {
      _firestore.collection('post').doc(postId).collection('comments').add({
        'text': commentText,
        'user': 'Current User', // Replace with actual user info
        'timestamp': FieldValue.serverTimestamp(),
      });

      _firestore.collection('post').doc(postId).update({
        'comment': FieldValue.increment(1),
      });
    }
  }

  bool shouldLoadMorePosts() {
    return true; // Example max posts
  }

  void loadMorePost() {
    loading.value = true;

    Future.delayed(const Duration(seconds: 2), () {
      posts.addAll(List.generate(
        5,
        (index) => posts.length + index,
      ));
      loading.value = false;
    });
  }

  @override
  void dispose() {
    textcontroller.dispose();
    scroll.dispose();
    super.dispose();
  }
}

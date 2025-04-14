import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:minimalsocialmedia/pages/user_profile_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToUserProfile(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UserProfilePage(
              userEmail: userData['email'],
              username: userData['username'] ?? 'Anonymous',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Explore", style: theme.textTheme.titleLarge),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),

          // Search results or suggested users
          Expanded(
            child:
                _searchQuery.isEmpty
                    ? _buildSuggestedUsers(theme)
                    : _buildSearchResults(theme),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
          color: theme.colorScheme.background,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomAppBar(
          elevation: 0,
          color: theme.colorScheme.background,
          child: SizedBox(
            height: 56.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.home_outlined, color: theme.iconTheme.color),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.explore, color: theme.colorScheme.primary),
                  onPressed: () {},
                ),
                Container(
                  width: 48,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add, color: Colors.white, size: 26),
                    onPressed: () {},
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.emoji_events_outlined,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/leaderboard_page',
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.person_outline,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/profile_page');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedUsers(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Users')
              .orderBy('username')
              .limit(20)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No users found', style: theme.textTheme.bodyMedium),
          );
        }

        return _buildUserList(snapshot.data!.docs, theme);
      },
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Users')
              .orderBy('username')
              .startAt([_searchQuery])
              .endAt([_searchQuery + '\uf8ff'])
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: theme.colorScheme.tertiary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text('No users found', style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }

        return _buildUserList(snapshot.data!.docs, theme);
      },
    );
  }

  Widget _buildUserList(List<QueryDocumentSnapshot> users, ThemeData theme) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Filter out the current user
    final filteredUsers =
        users.where((doc) {
          final userData = doc.data() as Map<String, dynamic>;
          return currentUser == null || userData['email'] != currentUser.email;
        }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No other users found'
              : 'No users found matching "$_searchQuery"',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredUsers.length,
      separatorBuilder:
          (context, index) =>
              Divider(color: theme.dividerColor, height: 1, indent: 70),
      itemBuilder: (context, index) {
        final userData = filteredUsers[index].data() as Map<String, dynamic>;
        final username = userData['username'] ?? 'Anonymous';
        final email = userData['email'] ?? '';
        final postsCount = userData['postsCount'] ?? 0;
        final followerCount = userData['followerCount'] ?? 0;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16,
          ),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: 24,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          title: Text(username, style: theme.textTheme.titleMedium),
          subtitle: Text(
            '$postsCount posts · $followerCount followers',
            style: theme.textTheme.bodySmall,
          ),
          trailing: Icon(Icons.chevron_right, color: theme.iconTheme.color),
          onTap: () => _navigateToUserProfile(context, userData),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }
}

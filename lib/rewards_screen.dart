import 'package:cotopay/account_settings_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRewardsMonthSelected = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final Color primaryGreen = const Color(0xff34A853);
  final Color lightGreenBackground = const Color(0xffEFF6F2);
  final Color darkTextColor = const Color(0xff434E58);
  final Color lightTextColor = Colors.black54;
  final Color circleBorderColor = const Color(0xffE0EBE4);

  void _showTrialPaymentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const TrialPaymentDialog();
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.sort, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsScreen()))),
            title: const Text('Reward', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            actions: [IconButton(icon: const Icon(Icons.download_outlined, color: Colors.black), onPressed: () {})],

          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWalletCard(),
                    const SizedBox(height: 24),
                    _buildRewardsToggleButtons(),
                    const SizedBox(height: 16),
                    _buildTierInfoCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: primaryGreen,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: primaryGreen,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                tabs: const [
                  Tab(text: 'Rewards Redemption'),
                  Tab(text: 'Rewards Earnings'),
                  Tab(text: 'Wallet Load'),
                ],
              ),
            ),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmptyStateTabContent(),
                  _buildEmptyStateTabContent(),
                  _buildEmptyStateTabContent(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Icon(Icons.sort, color: darkTextColor, size: 28),
        const SizedBox(width: 16),
        Text(
          'Hi, Rajesh',
          style: TextStyle(color: darkTextColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Icon(Icons.notifications_none, color: darkTextColor, size: 28),
      ],
    );
  }

  Widget _buildWalletCard() {
    return Container(
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'cotowallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'sans-serif',
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      '₹0.00',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Wallet Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.3)),
          Row(
            children: [
              // ** MODIFIED BUTTON ** - It now calls the dialog function.
              _walletButton('Trial', Icons.add, onPressed: _showTrialPaymentDialog),
              Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
              // The 'Redeem' button has a placeholder function for now.
              _walletButton('Redeem', Icons.north_east, isArrow: true, onPressed: () {}),
            ],
          )
        ],
      ),
    );
  }

  Widget _walletButton(String label, IconData icon, {bool isArrow = false, required VoidCallback onPressed}) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed, // Use the passed function here.
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Transform.rotate(
              angle: isArrow ? -45 * math.pi / 180 : 0,
              child: Icon(icon, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsToggleButtons() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isRewardsMonthSelected = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isRewardsMonthSelected ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Rewards this Month',
                    style: TextStyle(
                      color: _isRewardsMonthSelected ? Colors.white : lightTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isRewardsMonthSelected = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isRewardsMonthSelected ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Rewards Tier',
                    style: TextStyle(
                      color: !_isRewardsMonthSelected ? Colors.white : lightTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: lightGreenBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: const Text('Tier 1'),
                  backgroundColor: primaryGreen.withOpacity(0.2),
                  labelStyle: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                const SizedBox(height: 12),
                Divider(color: circleBorderColor, height: 1),
                const SizedBox(height: 12),
                Text('Current Spend', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Text('₹0.00', style: TextStyle(color: darkTextColor, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Divider(color: circleBorderColor, height: 1),
                const SizedBox(height: 12),
                Text('Rewards Earned', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Text('₹0.00', style: TextStyle(color: primaryGreen, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    height: 206,
                    width: 157,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: circleBorderColor,
                        width: 5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('₹1,00,000', style: TextStyle(color: darkTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('to go', style: TextStyle(color: primaryGreen, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      text: 'To earn more than ',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      children: [
                        TextSpan(
                          text: '₹500',
                          style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateTabContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have not made any redemptions from your CotoWallet yet.',
            style: TextStyle(
              color: darkTextColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Select 'Redeem' to use your CotoWallet. If you have redeemed your CotoWallet, please refresh and check this section again after 60 minutes.",
            style: TextStyle(
              color: lightTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// ** NEW WIDGET FOR THE DIALOG **
class TrialPaymentDialog extends StatefulWidget {
  const TrialPaymentDialog({super.key});

  @override
  State<TrialPaymentDialog> createState() => _TrialPaymentDialogState();
}

class _TrialPaymentDialogState extends State<TrialPaymentDialog> {
  // State variable to track the selected amount. Default is 2000 as per the image.
  int? _selectedValue = 2000;
  final List<int> _amounts = [500, 1000, 1500, 2000];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // To make the dialog wrap its content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product Trial Payment',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Select Amount for Product Trial',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          // Grid for amount options
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5, // Adjust aspect ratio for button size
            ),
            itemCount: _amounts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildAmountOption(_amounts[index]);
            },
          ),
          const SizedBox(height: 24),
          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add logic for continuing with the selected amount
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF), // Blue color
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'CONTINUE',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build each selectable amount option
  Widget _buildAmountOption(int value) {
    final bool isSelected = _selectedValue == value;
    final Color primaryGreen = const Color(0xff34A853);
    final Color lightGreyBg = Colors.grey.shade200;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedValue = value;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : lightGreyBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.white : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '₹${value.toString()}',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
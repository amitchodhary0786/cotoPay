import 'package:flutter/material.dart';

// Entry widget you can push from your app:
class AddUsersVehiclesScreen extends StatefulWidget {
  const AddUsersVehiclesScreen({Key? key}) : super(key: key);

  @override
  State<AddUsersVehiclesScreen> createState() => _AddUsersVehiclesScreenState();
}

class _AddUsersVehiclesScreenState extends State<AddUsersVehiclesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Tab> myTabs = const [
    Tab(text: 'Add Users'),
    Tab(text: 'Add Vehicles'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    // open different form depending on active tab
    final isUsers = _tabController.index == 0;
    if (isUsers) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddUserQuickScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Users & Vehicles'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: _onAddPressed,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
          indicatorColor: const Color(0xFF2F945A),
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Add Users Tab content: list of user cards (placeholder data)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView.separated(
              itemBuilder: (context, index) => _UserCard(
                name: 'Rakesh Kumar Jha Shrivastva',
                userType: 'Employee',
                mobile: '9910318123',
              ),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: 4,
            ),
          ),

          // Add Vehicles Tab: list of vehicles
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView.separated(
              itemBuilder: (context, index) => _VehicleCard(regNo: 'HR87L6621'),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: 3,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- Small UI cards used on main screen ---------- */

class _UserCard extends StatelessWidget {
  final String name;
  final String userType;
  final String mobile;

  const _UserCard({
    Key? key,
    required this.name,
    required this.userType,
    required this.mobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFEFEFEF),
                  child: Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User Type', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(userType, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mobile Number', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(mobile, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String regNo;
  const _VehicleCard({Key? key, required this.regNo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(regNo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Tap to view details'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailsScreen(regNo: regNo)));
        },
      ),
    );
  }
}

/* ---------- Add User Quick Screen (opened by + on Add Users) ---------- */

class AddUserQuickScreen extends StatefulWidget {
  const AddUserQuickScreen({Key? key}) : super(key: key);

  @override
  State<AddUserQuickScreen> createState() => _AddUserQuickScreenState();
}

class _AddUserQuickScreenState extends State<AddUserQuickScreen> {
  String _userType = 'Employee';
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _uploadMultiple = false;

  bool get _canAddOne => _nameController.text.trim().isNotEmpty && _mobileController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _onAddOne() {
    // For demo we open full add user screen and pass entered values
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddUserFullScreen(
          userType: _userType,
          initialName: _nameController.text.trim(),
          initialMobile: _mobileController.text.trim(),
        ),
      ),
    );
  }

  void _onUploadMultiple() {
    // show placeholder action; in real app show file picker or CSV upload
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload multiple tapped')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // greenish rounded box for radio buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Is this an employee or a contractor?',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Employee',
                        groupValue: _userType,
                        onChanged: (v) => setState(() => _userType = v!),
                      ),
                      const Text('Employee'),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'Contractor',
                        groupValue: _userType,
                        onChanged: (v) => setState(() => _userType = v!),
                      ),
                      const Text('Contractor'),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // Mobile
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter Mobile Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),

            const SizedBox(height: 18),

            // Add One button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _canAddOne ? _onAddOne : null,
                icon: const Icon(Icons.add),
                label: const Text('Add One'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canAddOne ? const Color(0xFF367AFF) : const Color(0xFFEBF2FF),
                  foregroundColor: _canAddOne ? Colors.white : const Color(0xFF4A4E69),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Upload Multiple
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _onUploadMultiple,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Multiple'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- Add User Full Screen (after quick add) ---------- */

class AddUserFullScreen extends StatelessWidget {
  final String userType;
  final String initialName;
  final String initialMobile;

  const AddUserFullScreen({
    Key? key,
    required this.userType,
    required this.initialName,
    required this.initialMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This screen replicates the 3rd screenshot — dropdowns, fields and Add button
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // small card with fields
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Select User Type dropdown
                    DropdownButtonFormField<String>(
                      value: userType,
                      items: const [
                        DropdownMenuItem(value: 'Employee', child: Text('Employee')),
                        DropdownMenuItem(value: 'Contractor', child: Text('Contractor')),
                      ],
                      onChanged: (_) {},
                      decoration: InputDecoration(
                        labelText: 'Select User Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name (dropdown style in screenshot)
                    TextFormField(
                      initialValue: initialName,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mobile
                    TextFormField(
                      initialValue: initialMobile,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // save user
                  Navigator.popUntil(context, (route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User added')));
                },
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Add'),
              ),
            ),

            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Add Multiple'),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- Add Vehicle Screen (opened by + when Add Vehicles tab active) ---------- */

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({Key? key}) : super(key: key);

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _regController = TextEditingController();

  bool get _canConfirm => _regController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _regController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    // navigate to vehicle details screen after confirmation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => VehicleDetailsScreen(regNo: _regController.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _regController,
              decoration: InputDecoration(
                hintText: 'Enter Registration Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canConfirm ? _onConfirm : null,
                child: const Text('Confirm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canConfirm ? const Color(0xFF367AFF) : const Color(0xFFEBF2FF),
                  foregroundColor: _canConfirm ? Colors.white : const Color(0xFF4A4E69),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------- Vehicle Details Screen (target after confirm) ---------- */

class VehicleDetailsScreen extends StatelessWidget {
  final String regNo;

  const VehicleDetailsScreen({Key? key, required this.regNo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // mimic the green info card from your screenshot
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Green card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2F945A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('Vehicle Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Registration Number', style: TextStyle(color: Colors.white70)),
                            Text(regNo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text('Vehicle Class', style: TextStyle(color: Colors.white70)),
                            const Text('Private Car (LMV)', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Car Make & Model', style: TextStyle(color: Colors.white70)),
                            Text('Volkswagen Virtus', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Text('Fuel', style: TextStyle(color: Colors.white70)),
                            Text('Diesel', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Additional Details (placeholder expandable)
            ExpansionTile(
              title: const Text('Additional Details'),
              children: const [
                ListTile(title: Text('Engine Number'), subtitle: Text('-')),
              ],
            ),

            ExpansionTile(
              title: const Text('Legal & Compliances'),
              children: const [
                ListTile(title: Text('RC Document'), subtitle: Text('-')),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Activate and go back to main listing
                  Navigator.popUntil(context, (route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle activated')));
                },
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('ACTIVATE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

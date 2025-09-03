// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// // You'll need to add these dependencies:
// // crypto: ^3.0.3
// // bip39: ^1.0.6
// // ed25519_hd_key: ^2.2.0
// // import 'package:crypto/crypto.dart';
// // import 'package:bip39/bip39.dart' as bip39;
// // import 'package:ed25519_hd_key/ed25519_hd_key.dart';

// class WalletImportScreen extends StatefulWidget {
//   final Function(String address, String privateKey) onWalletImported;

//   const WalletImportScreen({Key? key, required this.onWalletImported}) : super(key: key);

//   @override
//   _WalletImportScreenState createState() => _WalletImportScreenState();
// }

// class _WalletImportScreenState extends State<WalletImportScreen> with TickerProviderStateMixin {
//   final PageController _pageController = PageController();
//   final TextEditingController _seedPhraseController = TextEditingController();
//   final TextEditingController _privateKeyController = TextEditingController();
//   final GlobalKey<FormState> _seedFormKey = GlobalKey<FormState>();
//   final GlobalKey<FormState> _keyFormKey = GlobalKey<FormState>();
  
//   late AnimationController _glowController;
//   late AnimationController _slideController;
  
//   int currentPage = 0;
//   bool isLoading = false;
//   bool obscurePrivateKey = true;
//   bool obscureSeedPhrase = true;
  
//   List<String> seedWords = [];
//   final List<TextEditingController> wordControllers = List.generate(12, (index) => TextEditingController());

//   @override
//   void initState() {
//     super.initState();
//     _glowController = AnimationController(
//       duration: Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
    
//     _slideController = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _seedPhraseController.dispose();
//     _privateKeyController.dispose();
//     _glowController.dispose();
//     _slideController.dispose();
//     wordControllers.forEach((controller) => controller.dispose());
//     super.dispose();
//   }

//   // Generate new wallet with mnemonic
//   Map<String, String> generateNewWallet() {
//     // This is a simplified version - you'll need proper BIP39/ED25519 implementation
//     final mnemonic = generateMnemonic();
//     final keyPair = deriveKeyPairFromMnemonic(mnemonic);
    
//     return {
//       'mnemonic': mnemonic,
//       'privateKey': keyPair['privateKey']!,
//       'publicKey': keyPair['publicKey']!,
//       'address': keyPair['address']!,
//     };
//   }

//   // Import wallet from seed phrase
//   Future<void> importFromSeedPhrase() async {
//     if (!_seedFormKey.currentState!.validate()) return;
    
//     setState(() => isLoading = true);
    
//     try {
//       final seedPhrase = _seedPhraseController.text.trim();
      
//       // Validate mnemonic
//       if (!isValidMnemonic(seedPhrase)) {
//         throw 'Invalid seed phrase. Please check your words.';
//       }
      
//       // Derive key pair from mnemonic
//       final keyPair = deriveKeyPairFromMnemonic(seedPhrase);
      
//       widget.onWalletImported(keyPair['address']!, keyPair['privateKey']!);
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ Wallet imported successfully!'),
//           backgroundColor: Color(0xFF10B981),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
      
//       Navigator.of(context).pop();
      
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Import failed: $e'),
//           backgroundColor: Color(0xFFEF4444),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   // Import wallet from private key
//   Future<void> importFromPrivateKey() async {
//     if (!_keyFormKey.currentState!.validate()) return;
    
//     setState(() => isLoading = true);
    
//     try {
//       final privateKeyHex = _privateKeyController.text.trim();
      
//       // Validate private key format
//       if (!isValidPrivateKey(privateKeyHex)) {
//         throw 'Invalid private key format. Must be 64 hex characters.';
//       }
      
//       // Derive public key and address from private key
//       final keyPair = deriveKeyPairFromPrivateKey(privateKeyHex);
      
//       widget.onWalletImported(keyPair['address']!, privateKeyHex);
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('✅ Wallet imported successfully!'),
//           backgroundColor: Color(0xFF10B981),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
      
//       Navigator.of(context).pop();
      
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Import failed: $e'),
//           backgroundColor: Color(0xFFEF4444),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFF1A0B3D),
//               Color(0xFF0F172A),
//               Color(0xFF1E1B4B),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               _buildHeader(),
//               _buildTabSelector(),
//               Expanded(
//                 child: PageView(
//                   controller: _pageController,
//                   onPageChanged: (index) {
//                     setState(() => currentPage = index);
//                   },
//                   children: [
//                     _buildSeedPhraseImport(),
//                     _buildPrivateKeyImport(),
//                     _buildGenerateWallet(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: EdgeInsets.all(20),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: () => Navigator.of(context).pop(),
//             child: Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(Icons.arrow_back, color: Colors.white),
//             ),
//           ),
//           SizedBox(width: 20),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ShaderMask(
//                   shaderCallback: (bounds) => LinearGradient(
//                     colors: [Color(0xFF14F195), Color(0xFF9945FF)],
//                   ).createShader(bounds),
//                   child: Text(
//                     'Import Wallet',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 Text(
//                   'Restore your existing wallet',
//                   style: TextStyle(
//                     color: Colors.grey[400],
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabSelector() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 20),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           _buildTab('Seed Phrase', 0, Icons.text_fields_rounded),
//           _buildTab('Private Key', 1, Icons.key_rounded),
//           _buildTab('Generate New', 2, Icons.add_circle_outline),
//         ],
//       ),
//     );
//   }

//   Widget _buildTab(String title, int index, IconData icon) {
//     final isActive = currentPage == index;
    
//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           _pageController.animateToPage(
//             index,
//             duration: Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//           );
//         },
//         child: AnimatedContainer(
//           duration: Duration(milliseconds: 300),
//           margin: EdgeInsets.all(4),
//           padding: EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             gradient: isActive ? LinearGradient(
//               colors: [Color(0xFF14F195), Color(0xFF9945FF)],
//             ) : null,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 icon,
//                 color: isActive ? Colors.white : Colors.grey[400],
//                 size: 20,
//               ),
//               SizedBox(height: 4),
//               Text(
//                 title,
//                 style: TextStyle(
//                   color: isActive ? Colors.white : Colors.grey[400],
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSeedPhraseImport() {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(20),
//       child: Form(
//         key: _seedFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(height: 20),
//             Text(
//               'Enter your 12-word seed phrase',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Separate each word with spaces',
//               style: TextStyle(
//                 color: Colors.grey[400],
//                 fontSize: 14,
//               ),
//             ),
//             SizedBox(height: 30),
            
//             // Seed phrase input
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.white.withOpacity(0.05),
//                     Colors.white.withOpacity(0.02),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.1),
//                 ),
//               ),
//               child: TextFormField(
//                 controller: _seedPhraseController,
//                 maxLines: 4,
//                 obscureText: obscureSeedPhrase,
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                 ),
//                 decoration: InputDecoration(
//                   hintText: 'word1 word2 word3 ... word12',
//                   hintStyle: TextStyle(color: Colors.grey[500]),
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.all(20),
//                   suffixIcon: GestureDetector(
//                     onTap: () {
//                       setState(() => obscureSeedPhrase = !obscureSeedPhrase);
//                     },
//                     child: Icon(
//                       obscureSeedPhrase ? Icons.visibility : Icons.visibility_off,
//                       color: Colors.grey[400],
//                     ),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Please enter your seed phrase';
//                   }
//                   final words = value.trim().split(RegExp(r'\s+'));
//                   if (words.length != 12) {
//                     return 'Seed phrase must be exactly 12 words';
//                   }
//                   return null;
//                 },
//               ),
//             ),
            
//             SizedBox(height: 30),
            
//             // Import button
//             Container(
//               width: double.infinity,
//               height: 56,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF14F195), Color(0xFF9945FF)],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Color(0xFF14F195).withOpacity(0.3),
//                     blurRadius: 20,
//                     offset: Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: ElevatedButton(
//                 onPressed: isLoading ? null : importFromSeedPhrase,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.transparent,
//                   shadowColor: Colors.transparent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: isLoading
//                   ? CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation(Colors.white),
//                     )
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.download, size: 20),
//                         SizedBox(width: 8),
//                         Text(
//                           'Import Wallet',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//               ),
//             ),
            
//             SizedBox(height: 20),
            
//             // Security warning
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Color(0xFFEF4444).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: Color(0xFFEF4444).withOpacity(0.3),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.warning_rounded,
//                     color: Color(0xFFEF4444),
//                     size: 20,
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'Never share your seed phrase. Anyone with your seed phrase can access your wallet.',
//                       style: TextStyle(
//                         color: Color(0xFFEF4444),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPrivateKeyImport() {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(20),
//       child: Form(
//         key: _keyFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(height: 20),
//             Text(
//               'Enter your private key',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               '64-character hexadecimal string',
//               style: TextStyle(
//                 color: Colors.grey[400],
//                 fontSize: 14,
//               ),
//             ),
//             SizedBox(height: 30),
            
//             // Private key input
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.white.withOpacity(0.05),
//                     Colors.white.withOpacity(0.02),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.1),
//                 ),
//               ),
//               child: TextFormField(
//                 controller: _privateKeyController,
//                 obscureText: obscurePrivateKey,
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontFamily: 'monospace',
//                 ),
//                 decoration: InputDecoration(
//                   hintText: '0123456789abcdef...',
//                   hintStyle: TextStyle(color: Colors.grey[500]),
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.all(20),
//                   suffixIcon: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       GestureDetector(
//                         onTap: () async {
//                           final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
//                           if (clipboardData?.text != null) {
//                             _privateKeyController.text = clipboardData!.text!;
//                           }
//                         },
//                         child: Icon(
//                           Icons.paste,
//                           color: Colors.grey[400],
//                           size: 20,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() => obscurePrivateKey = !obscurePrivateKey);
//                         },
//                         child: Icon(
//                           obscurePrivateKey ? Icons.visibility : Icons.visibility_off,
//                           color: Colors.grey[400],
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                     ],
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Please enter your private key';
//                   }
//                   if (!isValidPrivateKey(value.trim())) {
//                     return 'Invalid private key format';
//                   }
//                   return null;
//                 },
//               ),
//             ),
            
//             SizedBox(height: 30),
            
//             // Import button
//             Container(
//               width: double.infinity,
//               height: 56,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF14F195), Color(0xFF9945FF)],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Color(0xFF14F195).withOpacity(0.3),
//                     blurRadius: 20,
//                     offset: Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: ElevatedButton(
//                 onPressed: isLoading ? null : importFromPrivateKey,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.transparent,
//                   shadowColor: Colors.transparent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: isLoading
//                   ? CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation(Colors.white),
//                     )
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.key, size: 20),
//                         SizedBox(width: 8),
//                         Text(
//                           'Import Wallet',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//               ),
//             ),
            
//             SizedBox(height: 20),
            
//             // Security warning
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Color(0xFFEF4444).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: Color(0xFFEF4444).withOpacity(0.3),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.security,
//                     color: Color(0xFFEF4444),
//                     size: 20,
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'Keep your private key secure. Never share it with anyone.',
//                       style: TextStyle(
//                         color: Color(0xFFEF4444),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGenerateWallet() {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(20),
//       child: Column(
//         children: [
//           SizedBox(height: 40),
          
//           // Animated icon
//           AnimatedBuilder(
//             animation: _glowController,
//             builder: (context, child) {
//               return Container(
//                 width: 120,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: RadialGradient(
//                     colors: [
//                       Color(0xFF14F195).withOpacity(0.3 + _glowController.value * 0.2),
//                       Color(0xFF9945FF).withOpacity(0.2 + _glowController.value * 0.1),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//                 child: Icon(
//                   Icons.account_balance_wallet_outlined,
//                   size: 60,
//                   color: Colors.white,
//                 ),
//               );
//             },
//           ),
          
//           SizedBox(height: 40),
          
//           Text(
//             'Generate New Wallet',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
          
//           SizedBox(height: 16),
          
//           Text(
//             'Create a brand new Solana wallet\nwith a secure seed phrase',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: Colors.grey[400],
//               fontSize: 16,
//               height: 1.5,
//             ),
//           ),
          
//           SizedBox(height: 50),
          
//           // Generate button
//           Container(
//             width: double.infinity,
//             height: 56,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF14F195), Color(0xFF9945FF)],
//               ),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Color(0xFF14F195).withOpacity(0.3),
//                   blurRadius: 20,
//                   offset: Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: ElevatedButton(
//               onPressed: () {
//                 _showGenerateWalletDialog();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 shadowColor: Colors.transparent,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.add_circle_outline, size: 20),
//                   SizedBox(width: 8),
//                   Text(
//                     'Generate New Wallet',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
          
//           SizedBox(height: 30),
          
//           // Info card
//           Container(
//             padding: EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF06B6D4).withOpacity(0.1),
//                   Color(0xFF8B5CF6).withOpacity(0.05),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: Color(0xFF06B6D4).withOpacity(0.2),
//               ),
//             ),
//             child: Column(
//               children: [
//                 Icon(
//                   Icons.info_outline,
//                   color: Color(0xFF06B6D4),
//                   size: 24,
//                 ),
//                 SizedBox(height: 12),
//                 Text(
//                   'What you\'ll get:',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 SizedBox(height: 12),
//                 Text(
//                   '• New Solana wallet address\n• 12-word recovery phrase\n• Private key for advanced use\n• Full control of your funds',
//                   style: TextStyle(
//                     color: Colors.grey[300],
//                     fontSize: 14,
//                     height: 1.6,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showGenerateWalletDialog() {
//     final newWallet = generateNewWallet();
    
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           padding: EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color(0xFF1A0B3D).withOpacity(0.95),
//                 Color(0xFF0F172A).withOpacity(0.98),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: Color(0xFF14F195).withOpacity(0.3),
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.check_circle,
//                 color: Color(0xFF10B981),
//                 size: 48,
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Wallet Generated!',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 'Your seed phrase:',
//                 style: TextStyle(
//                   color: Colors.grey[400],
//                   fontSize: 14,
//                 ),
//               ),
//               SizedBox(height: 8),
//               Container(
//                 padding: EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.3),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   newWallet['mnemonic']!,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 'Save this phrase securely!\nYou\'ll need it to recover your wallet.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Color(0xFFEF4444),
//                   fontSize: 14,
//                 ),
//               ),
//               SizedBox(height: 24),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.grey[700],
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: Text('Cancel'),
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                         widget.onWalletImported(newWallet['address']!, newWallet['privateKey']!);
//                         Navigator.of(context).pop();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF10B981),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: Text('Use Wallet'),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Helper functions (you'll need to implement these with proper crypto libraries)
// String generateMnemonic() {
//   // Implement with bip39.generateMnemonic()
//   final words = ['abandon', 'ability', 'able', 'about', 'above', 'absent', 'absorb', 'abstract', 'absurd', 'abuse', 'access', 'accident']; // This is just example
//   return words.join(' ');
// }

// bool isValidMnemonic(String mnemonic) {
//   // Implement with bip39.validateMnemonic(mnemonic)
//   final words = mnemonic.trim().split(RegExp(r'\s+'));
//   return words.length == 12; // Simplified validation
// }

// bool isValidPrivateKey(String privateKey) {
//   // Check if it's a valid 64-character hex string
//   final hexPattern = RegExp(r'^[0-9a-fA-F]{64}$');
//   return hexPattern.hasMatch(privateKey);
// }

// Map<String, String> deriveKeyPairFromMnemonic(String mnemonic) {
//   // Implement with proper BIP39
//   final seed = bip39.mnemonicToSeed(mnemonic);
//   final root = bip32.BIP32.fromSeed(seed);
//   final child = root.derivePath("m/44'/501'/0'/0/0");
//   return {
//     'address': child.publicKey.toString(),
//     'privateKey': child.privateKey.toString(),
//   };
// }
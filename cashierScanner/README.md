# 🏪 Cashier Scanner

A Flutter web app for restaurant staff to scan customer QR codes and award loyalty coins.

## 🚀 Features

- **📱 QR Code Scanning** - Camera-based QR code detection
- **👤 User Recognition** - Displays customer info and current coins
- **💰 Coin Distribution** - Calculate and award coins based on purchase amount
- **🎮 Game Reset** - Automatically sets `hasPlayed: false` so customers can play
- **📊 Real-time Updates** - Instant Firebase synchronization
- **🎨 Dashboard Design** - Same styling as the main dashboard

## 🔧 Setup

1. **Install Dependencies**
   ```bash
   cd cashierScanner
   flutter pub get
   ```

2. **Configure Firebase**
   - Update `lib/backend/firebase_options.dart` with your Firebase config
   - Ensure Firestore rules allow writes to `userVenueProgress` collection

3. **Run Locally**
   ```bash
   flutter run -d chrome
   ```

4. **Build for Production**
   ```bash
   flutter build web
   ```

## 📱 Usage

1. **Open the app** on a tablet or mobile device
2. **Tap "SCAN QR"** to start the camera scanner
3. **Point at customer QR code** - format: `userId-venueId`
4. **Enter purchase amount** in HK$ (e.g., 25.50)
5. **Tap "AWARD COINS"** - coins calculated at 80% rate
6. **Success!** Customer can now play the loyalty game

## 🔄 Coin Calculation

- **Rate**: HK$1 = 0.8 coins
- **Example**: HK$25 purchase = 20 coins awarded
- **Formula**: `Math.ceil(amount * 0.8)`

## 🎯 Firebase Updates

When coins are awarded, the app updates:
```javascript
{
  coin: currentCoins + awardedCoins,           // Total coins
  coinsFromVenue: venueCoins + awardedCoins,   // Venue-distributed coins
  hasPlayed: false,                            // Allow game play
  lastCoinUpdate: serverTimestamp()            // Track update time
}
```

## 📊 Integration

- **Same Firebase** - Uses existing `locotag` project
- **Same Users** - Reads from `userVenueProgress` collection
- **Real-time** - Updates sync instantly with loyalty app
- **No Auth** - Direct access for staff convenience

## 🎨 Design

- **Dark Theme** - `#1F2029` background (same as dashboard)
- **Gradient Cards** - Purple/blue gradients for consistency
- **Roboto Flex** - Same font family as dashboard
- **Mobile-First** - Optimized for tablets and phones

## 🔒 Security

- **Read-Only User Data** - Only displays customer info
- **Controlled Coin Awards** - Staff enters purchase amounts
- **Firebase Rules** - Ensure proper access controls
- **No Authentication** - Simplified for staff workflow

## 🌐 Deployment

Deploy alongside main dashboard:
- **Dashboard**: `yourdomain.com/dashboard`
- **Cashier**: `yourdomain.com/cashier`

## 📞 Support

For issues or questions, check the main dashboard documentation or Firebase console logs.

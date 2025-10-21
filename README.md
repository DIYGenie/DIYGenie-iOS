# DIY Genie

DIY Genie is a React Native mobile application built with Expo, designed to assist users with DIY furniture and home improvement projects. The app provides AI-powered build plans with visual preview integration and follows the tagline "Wish. See. Build."

## Features

- **AI-Powered Build Plans**: Get detailed step-by-step instructions for your DIY projects
- **Visual Mockup Preview**: See what your finished project will look like with AI-generated previews
- **Room Scanning**: Use AR capabilities to scan your space and get accurate measurements
- **Progress Tracking**: Track your build progress step by step
- **Project Management**: Save, organize, and manage multiple DIY projects
- **Template Library**: Start with pre-configured project templates (shelves, accent walls, benches, etc.)

## Tech Stack

- **Frontend**: React Native (Expo SDK 54)
- **Navigation**: React Navigation v7
- **Backend**: Express.js
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage
- **Platform Support**: iOS, Android, Web

## Getting Started

### Prerequisites

- Node.js 18+ 
- Expo CLI
- Supabase account

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/DIYGenie/DIYGenieTheme.git
   cd DIYGenieTheme
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and fill in your configuration values:
   - `EXPO_PUBLIC_BASE_URL`: Your API backend URL
   - `EXPO_PUBLIC_SUPABASE_URL`: Your Supabase project URL
   - `EXPO_PUBLIC_SUPABASE_ANON_KEY`: Your Supabase anonymous key

4. Set server-side secrets (for backend server):
   - `SUPABASE_SERVICE_KEY`: Your Supabase service role key
   - `SESSION_SECRET`: A secure random string for sessions

### Running the App

#### Development Mode

Start the Expo development server:
```bash
npm start
```

Then:
- Press `w` to open in web browser
- Press `a` to open in Android emulator
- Press `i` to open in iOS simulator
- Scan the QR code with Expo Go app on your mobile device

#### Backend Server

Start the Express backend server:
```bash
node server.js
```

The server will run on port 3001 by default.

## Project Structure

```
DIYGenieTheme/
├── app/                    # React Native application code
│   ├── components/         # Reusable UI components
│   ├── lib/               # Utility functions and API helpers
│   ├── navigation/        # Navigation configuration
│   ├── screens/           # App screens
│   └── ui/                # UI kit and theme tokens
├── assets/                # Images, fonts, and static assets
├── docs/                  # Documentation
├── server.js              # Express backend server
├── app.config.js          # Expo configuration
└── package.json           # Dependencies and scripts
```

## Building for Production

### iOS

```bash
eas build --platform ios
```

### Android

```bash
eas build --platform android
```

### Web

```bash
npx expo export:web
```

## Environment Variables

### Client-side (EXPO_PUBLIC_*)
These are bundled into the app and are safe to be public:
- `EXPO_PUBLIC_BASE_URL`: API endpoint
- `EXPO_PUBLIC_SUPABASE_URL`: Supabase project URL
- `EXPO_PUBLIC_SUPABASE_ANON_KEY`: Supabase anonymous key (public)

### Server-side (Secrets)
These must never be committed to Git:
- `SUPABASE_SERVICE_KEY`: Backend service role key
- `SESSION_SECRET`: Session encryption key

## Contributing

This is a private project. For questions or issues, please contact the maintainers.

## License

Proprietary - All rights reserved

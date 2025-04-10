# RStream - Modern IPTV Streaming App

RStream is a feature-rich IPTV streaming application built with Flutter, offering a modern user interface and advanced features like watch parties, subscription management, and real-time chat.

## Features

### Content Library
- Movies, TV series, and live channels
- HD and 4K quality streaming
- Categories and genre filtering
- Search functionality
- Trending content recommendations

### Watch Parties
- Create and join watch parties
- Real-time video synchronization
- Live chat during playback
- Invite friends to watch together
- Party host controls

### Subscription System
- Multiple subscription tiers
- Flexible payment options
- Location-based free subscriptions
- Auto-renewal management
- Multi-device support

### Admin Panel
- Content management
- User management
- Subscription control
- Analytics dashboard
- System settings

## Tech Stack

- **Frontend & Backend**: Flutter/Dart
- **Database**: SQLite
- **State Management**: Provider
- **Video Player**: video_player, chewie
- **Real-time Features**: WebSocket
- **Authentication**: flutter_secure_storage, crypto
- **UI Components**: Material Design, custom widgets
- **Network**: dio for HTTP requests
- **Location Services**: geolocator
- **Caching**: cached_network_image

## Project Structure

```
lib/
├── config/
│   ├── theme.dart
│   ├── routes.dart
│   └── constants.dart
├── models/
│   ├── user.dart
│   ├── content.dart
│   ├── subscription.dart
│   └── watch_party.dart
├── screens/
│   ├── main_screen.dart
│   ├── content_library_screen.dart
│   ├── subscription_screen.dart
│   ├── watch_party_screen.dart
│   └── admin_panel_screen.dart
├── services/
│   ├── database_service.dart
│   ├── auth_service.dart
│   ├── content_service.dart
│   ├── subscription_service.dart
│   └── watch_party_service.dart
├── widgets/
│   ├── custom_app_bar.dart
│   ├── content_card.dart
│   ├── trending_carousel.dart
│   └── category_selector.dart
└── main.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/rstream.git
```

2. Navigate to the project directory:
```bash
cd rstream
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

### Configuration

1. Update the database configuration in `database_service.dart`
2. Configure WebSocket endpoints in `watch_party_service.dart`
3. Set up authentication parameters in `auth_service.dart`
4. Adjust subscription plans in `subscription_service.dart`

## Development Guidelines

### Code Style
- Follow Flutter/Dart style guidelines
- Use meaningful variable and function names
- Write comments for complex logic
- Keep functions small and focused
- Use const constructors when possible

### State Management
- Use Provider for app-wide state
- Keep business logic in services
- Handle errors gracefully
- Implement proper loading states

### UI/UX Guidelines
- Follow Material Design principles
- Maintain consistent spacing
- Use the defined color scheme
- Implement smooth animations
- Ensure responsive layouts

### Testing
- Write unit tests for services
- Create widget tests for UI components
- Perform integration testing
- Test edge cases and error scenarios

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Contributors and maintainers
- Open source community

## Contact

For support or queries:
- Email: support@rstream.com
- Website: https://rstream.com
- Twitter: @RStream

## Roadmap

### Version 1.1
- Offline content download
- Enhanced search functionality
- Social features integration
- Performance optimizations

### Version 1.2
- Multi-language support
- Advanced content recommendations
- Payment gateway integration
- Analytics dashboard

### Version 1.3
- Cross-platform sync
- Content sharing features
- Enhanced admin controls
- API documentation

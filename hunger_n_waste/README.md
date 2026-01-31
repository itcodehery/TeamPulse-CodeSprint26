# Project Name: Morsels
### Problem Statement ID: CS01SW
### Team Name: Team Pulse
### College Name: CHRIST (Deemed to be University), Central Campus

---

## Problem Statement
Food waste and hunger are two simultaneous global crises. While massive amounts of food are discarded daily, many communities struggle with food insecurity. The lack of a streamlined logistics network makes it difficult to transfer surplus food to those in need quickly and safely.

## Proposed Solution
**Morsels** is a digital platform designed to bridge the gap between surplus food sources and NGOs. By leveraging real-time location services, the application connects donors with verified organizations to facilitate the efficient redistribution of food.

Our mobile application:
- **Connects** donors (Caterers, Event Organizers, Individuals) with nearby verified NGOs via an intuitive map interface.
- **Facilitates** real-time pickup requests for surplus food with "active/available" status tracking.
- **Empowers** riders to discover, accept, and fulfill deliveries manually, ensuring autonomy and better logistics management.
- **Ensures** trust through a robust "Proof of Service" workflow, requiring photographic evidence at both pickup and drop-off points.

## Innovation & Creativity
- **Real-Time Surplus Logistics**: Unlike static directories, our app facilitates dynamic, real-time pickup and delivery of perishable goods using geolocation and live status updates.
- **Role-Based Ecosystem**: Integrates three distinct user roles (Donor, NGO, Rider) into a single cohesive ecosystem, each with specialized dashboards.
- **Digital Proof of Service**: Includes a custom-built Camera interface that overlays location coordinates and timestamps on pickup/delivery photos, ensuring absolute transparency and trust in the redistribution chain.
- **Smart Rider Discovery**: Instead of rigid auto-assignment, we implemented a "First-to-Claim" availability model where qualified riders within proximity can view and accept jobs that fit their schedule.

## Technical Complexity & Stack
This project leverages a modern, cross-platform tech stack to ensure performance and scalability:

- **Mobile Framework**: Flutter (SDK ^3.10.4) - For a high-performance, cross-platform (iOS/Android) user interface with premium "Glassmorphism" UI design.
- **Backend & Database**: Supabase - Utilized for PostgreSQL database, Authentication, and Realtime subscriptions.
- **State Management**: `flutter_riverpod` - For robust, scalable, and testable application state management.
- **Maps & Location Services**: 
  - `flutter_map` & `latlong2`: For rendering performant, interactive OpenStreetMap tiles with custom markers.
  - `geolocator`: For precise real-time user location tracking.
- **Hardware Integration**:
  - `camera`: Custom camera implementation for capturing verification images.
  - `vibration`: Haptic feedback for critical rider alerts (e.g., new order buzz).
- **Routing**: `go_router` - For declarative and deep-linkable navigation.
- **Typography**: `google_fonts` - Utilizing modern typefaces (Outfit) for a polished aesthetic.
- **Architecture**: Feature-first architecture ensuring modularity and maintainability.

## Usability & Impact
**Users:**
1.  **Donors**: Individuals, restaurants, or event organizers who have surplus food.
2.  **NGOs**: Verified non-profit organizations seeking food for their beneficiaries.
3.  **Riders**: Volunteers or logistics partners who transport the food.

**Interaction:**
- **Donors** post surplus food with quantity and type; requests are instantly broadcasted.
- **Riders** receive a haptic "buzz" notification for new orders, view them on a map, and accept them manually.
- **Verification**: Riders must capture a photo at the pickup point (Donor location) and drop-off point (NGO location) to progress the order status, ensuring quality and accountability.

**Impact:**
- **Social**: Directly alleviates hunger in local communities by routing excess food to where it's needed most with a verifiable chain of custody.
- **Environmental*: Reduces food waste, thereby lowering the carbon footprint associated with decomposing organic waste in landfills.

## Setup Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured.
- A [Supabase](https://supabase.com/) project set up.

### Installation

1.  **Clone the Repository**
    ```bash
    git clone <repository-url>
    cd TeamPulse-CodeSprint26/hunger_n_waste
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Configuration**
    Create a `.env` file in the `hunger_n_waste` root directory and add your Supabase credentials:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```

4.  **Database Setup**
    The application requires specific database tables, types, and RLS policies.
    👉 *[View the detailed Supabase Setup Guide](supabase_setup.md)* (if available) or ensure tables `rider_profiles`, `food_requests`, `organizations`, `donors` are created.

5.  **Run the Application**
    ```bash
    flutter run
    ```

## Presentation/Demo Link (Optional)
https://www.canva.com/design/DAG_6F8yvZE/jRHUYZon5fQ9f1FXYvJ6Ow/view?utm_content=DAG_6F8yvZE&utm_campaign=designshare&utm_medium=link2&utm_source=uniquelinks&utlId=ha19d8485f9

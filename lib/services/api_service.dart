import 'package:leavesync/config/api_config.dart';

class ApiService {

  // ===== AUTH =====
  static Uri login() {
    return Uri.parse("${ApiConfig.baseUrl}/api/login");
  }

  static Uri register() {
    return Uri.parse("${ApiConfig.baseUrl}/api/register");
  }

  // ===== PROFILE =====
  static Uri profile() {
    return Uri.parse("${ApiConfig.baseUrl}/api/user/profile");
  }

  static Uri updateProfile() {
    return Uri.parse("${ApiConfig.baseUrl}/api/user/profile/update");
  }

  // ===== LEAVE =====
  static Uri submitLeave() {
    return Uri.parse("${ApiConfig.baseUrl}/api/leave-request");
  }

  static Uri leaveBalance(int userId) {
    return Uri.parse("${ApiConfig.baseUrl}/api/user/$userId/leave-balance");
  }

  static Uri leaveSummary(int userId) {
    return Uri.parse("${ApiConfig.baseUrl}/api/leave/summary?user_id=$userId");
  }

  static Uri leaveEvents() {
    return Uri.parse("${ApiConfig.baseUrl}/api/leaves/all");
  }

  static Uri leaveSearch(Map<String, String> queryParams) {
  return Uri.parse("${ApiConfig.baseUrl}/api/leave/search")
      .replace(queryParameters: queryParams);
}

  // ===== HOLIDAY =====
  static Uri holidays() {
    return Uri.parse("${ApiConfig.baseUrl}/api/holidays");
  }
}

class ApiEndpoints {
  // --- Auth (Customer) ---
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String changePassword = '/api/auth/change-password';
  static const String profile = '/api/auth/profile';

  // --- Products ---
  static const String products = '/api/products';

  static String productDetails(String id) => '/api/products/$id';

  // --- Cart ---
  static const String cartAdd = '/api/cart/add';
  static const String cartClear = '/api/cart/clear';

  static String cartGet(String userId) => '/api/cart/$userId';

  static String cartUpdate(String id) => '/api/cart/update/$id';

  static String cartRemove(String id) => '/api/cart/remove/$id';

  // --- Orders (Customer) ---
  static const String checkout = '/api/orders/checkout';
  static const String userOrders = '/api/orders';

  static String orderDetails(String id) => '/api/orders/$id';

  static String cancelOrder(String id) => '/api/orders/$id/cancel';

  static String cancelOrderItem(String orderId, String itemId) =>
      '/api/orders/$orderId/cancel-item/$itemId';

  static String trackOrder(String id) => '/api/orders/track/$id';

  // --- Admin Endpoints ---
  static const String adminLogin = '/api/admin/login';
  static const String adminDashboardStats = '/api/admin/dashboard/stats';
  static const String adminVendors = '/api/admin/vendors';
  static const String deliveryLogin = '/api/orders/delivery/login';
  static const String deliveryTasks = '/api/orders/delivery/my-tasks';

  static String updateDeliveryTaskStatus(String id) =>
      '/api/orders/delivery/update-status/$id';
  static const String deliveryLogout = '/api/orders/delivery/logout';
  static const String deliveryProfile = '/api/orders/delivery/profile';
  static const String deliveryChangePassword =
      '/api/orders/delivery/change-password';

  static String approveVendor(String id) => '/api/admin/vendors/$id/approve';

  static String rejectVendor(String id) => '/api/admin/vendors/$id/reject';

  static const String adminAllOrders = '/api/orders/admin/all';

  static String adminOrderDetails(String id) => '/api/orders/admin/$id';

  static String adminUpdateItemStatus(String id) =>
      '/api/orders/admin/item/$id';

  static String adminUpdateOrderStatus(String id) =>
      '/api/orders/admin/$id/status';

  static const String deliveryBoys = '/api/orders/admin/delivery-boys';

  static String deleteDeliveryBoy(String id) =>
      '/api/orders/admin/delivery-boys/$id';

  static String assignDeliveryBoy(String orderId) =>
      '/api/orders/$orderId/assign';

  // --- Vendor Endpoints ---
  static const String vendorLogin = '/api/vendor/login';
  static const String vendorRegister = '/api/vendor/register';
  static const String vendorMyProducts = '/api/products/vendor/my-products';
}

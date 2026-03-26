enum AppSection {
  dashboard,
  bookings,
  profileManagement,
  meetingAndNotice,
  ticketManagement,
  security,
  groupManagement,
  staffManagement,
  vendorManagement,
  roleAndAccess,
  reports,
  others,
  finance,
}

extension AppSectionX on AppSection {
  String get title {
    switch (this) {
      case AppSection.dashboard:
        return 'Dashboard';
      case AppSection.bookings:
        return 'Bookings';
      case AppSection.profileManagement:
        return 'Profile Management';
      case AppSection.meetingAndNotice:
        return 'Meeting And Notice Management';
      case AppSection.ticketManagement:
        return 'Ticket Management';
      case AppSection.security:
        return 'Security';
      case AppSection.groupManagement:
        return 'Group Management';
      case AppSection.staffManagement:
        return 'Staff Management';
      case AppSection.vendorManagement:
        return 'Vendor Management';
      case AppSection.roleAndAccess:
        return 'Role And Access';
      case AppSection.reports:
        return 'Reports';
      case AppSection.others:
        return 'Others';
      case AppSection.finance:
        return 'Finance';
    }
  }
}

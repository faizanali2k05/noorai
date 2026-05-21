import 'package:flutter/material.dart';

/// A general home-services category shown in the "More Services" grid.
class ServiceCategory {
  final String id;
  final String label;
  final IconData icon;
  final String hint;

  const ServiceCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.hint,
  });
}

/// The fixed catalog of general informal-economy services. The core NoorAI
/// experience (special-needs therapists) lives separately on the Find tab.
const List<ServiceCategory> kServiceCategories = [
  ServiceCategory(
    id: 'ac_technician',
    label: 'AC Technician',
    icon: Icons.ac_unit,
    hint: 'Kal subah G-13 mein AC technician chahiye',
  ),
  ServiceCategory(
    id: 'plumber',
    label: 'Plumber',
    icon: Icons.plumbing,
    hint: 'Nalka leak ho raha hai, plumber chahiye Gulberg',
  ),
  ServiceCategory(
    id: 'electrician',
    label: 'Electrician',
    icon: Icons.electrical_services,
    hint: 'Bijli ki wiring ka kaam, electrician chahiye F-11',
  ),
  ServiceCategory(
    id: 'carpenter',
    label: 'Carpenter',
    icon: Icons.handyman,
    hint: 'Furniture repair ke liye carpenter Model Town',
  ),
  ServiceCategory(
    id: 'painter',
    label: 'Painter',
    icon: Icons.format_paint,
    hint: 'Ghar paint karwana hai DHA Karachi',
  ),
  ServiceCategory(
    id: 'home_cleaning',
    label: 'Home Cleaning',
    icon: Icons.cleaning_services,
    hint: 'Ghar ki deep cleaning chahiye Gulberg Lahore',
  ),
  ServiceCategory(
    id: 'appliance_repair',
    label: 'Appliance Repair',
    icon: Icons.kitchen,
    hint: 'Fridge repair karana hai Gulshan Karachi',
  ),
  ServiceCategory(
    id: 'tutor',
    label: 'Home Tutor',
    icon: Icons.menu_book,
    hint: 'O Level Maths tutor chahiye DHA Lahore',
  ),
  ServiceCategory(
    id: 'beautician',
    label: 'Beautician',
    icon: Icons.spa,
    hint: 'Bridal makeup home service Gulberg',
  ),
  ServiceCategory(
    id: 'car_mechanic',
    label: 'Car Mechanic',
    icon: Icons.directions_car,
    hint: 'Car repair doorstep service F-10 Islamabad',
  ),
];

/// Human label for a category id (falls back to a title-cased id).
String serviceCategoryLabel(String id) {
  for (final c in kServiceCategories) {
    if (c.id == id) return c.label;
  }
  return id
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

IconData serviceCategoryIcon(String id) {
  for (final c in kServiceCategories) {
    if (c.id == id) return c.icon;
  }
  return Icons.home_repair_service;
}

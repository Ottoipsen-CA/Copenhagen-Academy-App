import '../models/development_plan.dart';

// Temporary stub service until backend is ready
class DevelopmentPlanService {
  // Get development plans from the API
  Future<List<DevelopmentPlan>> getDevelopmentPlans() async {
    // Return an empty list for now
    return [];
  }

  // Create a new development plan
  Future<DevelopmentPlan?> createDevelopmentPlan(DevelopmentPlan plan) async {
    // Just return the plan for now (simulating creation)
    return plan;
  }

  // Update an existing development plan
  Future<DevelopmentPlan?> updateDevelopmentPlan(DevelopmentPlan plan) async {
    // Just return the plan for now (simulating update)
    return plan;
  }

  // Delete a development plan
  Future<bool> deleteDevelopmentPlan(int planId) async {
    // Return success for now
    return true;
  }

  // Add a focus area to a plan
  Future<FocusArea?> addFocusArea(int planId, FocusArea focusArea) async {
    // Just return the focus area for now
    return focusArea;
  }

  // Update a focus area
  Future<FocusArea?> updateFocusArea(int planId, FocusArea focusArea) async {
    // Just return the focus area for now
    return focusArea;
  }

  // Delete a focus area
  Future<bool> deleteFocusArea(int planId, int focusAreaId) async {
    // Return success for now
    return true;
  }
} 
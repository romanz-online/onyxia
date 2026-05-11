import 'package:flutter/material.dart';

/// Utility class for calculating positions along arrow paths
class ArrowPathHelper {
  /// Returns a point at the given percentage (0.0-1.0) along the arrow's path
  static Offset getPointAtPercentage(List<Offset> points, double percentage) {
    if (points.length < 2) return Offset.zero;
    
    // Calculate segment lengths
    final segmentLengths = _getSegmentLengths(points);
    final totalLength = segmentLengths.fold(0.0, (sum, length) => sum + length);
    
    // Handle edge cases
    if (totalLength == 0.0) return points.first;
    
    // Find target distance along path
    final targetDistance = totalLength * percentage.clamp(0.0, 1.0);
    
    // Find which segment contains the target point
    double accumulatedDistance = 0.0;
    for (int i = 0; i < segmentLengths.length; i++) {
      final segmentLength = segmentLengths[i];
      if (accumulatedDistance + segmentLength >= targetDistance) {
        // Interpolate within this segment
        final segmentProgress = segmentLength > 0 
            ? (targetDistance - accumulatedDistance) / segmentLength 
            : 0.0;
        return Offset.lerp(points[i], points[i + 1], segmentProgress)!;
      }
      accumulatedDistance += segmentLength;
    }
    
    // Fallback to last point
    return points.last;
  }
  
  /// Calculates the percentage along the arrow path for a given point
  /// Finds the closest point on the arrow path and returns its percentage (0.0-1.0)
  static double getPercentageAtPoint(List<Offset> points, Offset targetPoint) {
    if (points.length < 2) return 0.0;
    
    final segmentLengths = _getSegmentLengths(points);
    final totalLength = segmentLengths.fold(0.0, (sum, length) => sum + length);
    
    if (totalLength == 0.0) return 0.0;
    
    double closestDistance = double.infinity;
    double closestPercentage = 0.0;
    double accumulatedDistance = 0.0;
    
    // Check each segment for the closest point
    for (int i = 0; i < points.length - 1; i++) {
      final segmentStart = points[i];
      final segmentEnd = points[i + 1];
      final segmentLength = segmentLengths[i];
      
      // Find closest point on this segment
      final closestPointOnSegment = _getClosestPointOnLineSegment(
        segmentStart, 
        segmentEnd, 
        targetPoint
      );
      
      final distanceToSegment = (targetPoint - closestPointOnSegment).distance;
      
      if (distanceToSegment < closestDistance) {
        closestDistance = distanceToSegment;
        
        // Calculate percentage along this segment
        final segmentProgress = segmentLength > 0 
            ? (closestPointOnSegment - segmentStart).distance / segmentLength 
            : 0.0;
        
        // Convert to overall percentage
        closestPercentage = (accumulatedDistance + segmentProgress * segmentLength) / totalLength;
      }
      
      accumulatedDistance += segmentLength;
    }
    
    return closestPercentage.clamp(0.0, 1.0);
  }
  
  /// Calculates the lengths of each segment in the path
  static List<double> _getSegmentLengths(List<Offset> points) {
    final segmentLengths = <double>[];
    
    for (int i = 0; i < points.length - 1; i++) {
      final distance = (points[i + 1] - points[i]).distance;
      segmentLengths.add(distance);
    }
    
    return segmentLengths;
  }
  
  /// Finds the closest point on a line segment to a given point
  static Offset _getClosestPointOnLineSegment(Offset lineStart, Offset lineEnd, Offset point) {
    final lineVector = lineEnd - lineStart;
    final lineLength = lineVector.distance;
    
    if (lineLength == 0.0) {
      return lineStart; // Line segment is actually a point
    }
    
    // Calculate projection parameter t
    final pointVector = point - lineStart;
    final t = (pointVector.dx * lineVector.dx + pointVector.dy * lineVector.dy) / (lineLength * lineLength);
    
    // Clamp t to [0, 1] to stay within the line segment
    final clampedT = t.clamp(0.0, 1.0);
    
    // Return the closest point on the line segment
    return lineStart + lineVector * clampedT;
  }
  
  /// Gets the total length of the arrow path
  static double getTotalPathLength(List<Offset> points) {
    if (points.length < 2) return 0.0;
    
    final segmentLengths = _getSegmentLengths(points);
    return segmentLengths.fold(0.0, (sum, length) => sum + length);
  }
}
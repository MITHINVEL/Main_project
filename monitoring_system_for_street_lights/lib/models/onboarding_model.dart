class OnboardingContent {
  final String title;
  final String description;
  final String animationPath;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.animationPath,
  });
}

List<OnboardingContent> onboardingContents = [
  OnboardingContent(
    title: "Smart Street Light Monitoring",
    description:
        "Monitor and control street lights across your city with real-time data and intelligent automation.",
    animationPath: "assets/lottie/street_light.json",
  ),
  OnboardingContent(
    title: "Real-time Analytics",
    description:
        "Get instant insights on power consumption, operational status, and maintenance requirements.",
    animationPath: "assets/lottie/monitoring.json",
  ),
  OnboardingContent(
    title: "Smart City Solutions",
    description:
        "Be part of the smart city revolution with efficient, sustainable, and intelligent lighting systems.",
    animationPath: "assets/lottie/smart_city.json",
  ),
];

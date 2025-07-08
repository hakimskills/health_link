import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:health_link/screens/terms_dialogue.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'login_screen.dart';
import 'success_screen.dart';

class RegisterScreen extends HookWidget {
  final String? selectedRole; // Made nullable to make it optional

  RegisterScreen({Key? key, this.selectedRole})
      : super(key: key); // No longer required

  final List<String> _wilayas = [
    "Adrar",
    "Chlef",
    "Laghouat",
    "Oum El Bouaghi",
    "Batna",
    "Béjaïa",
    "Biskra",
    "Béchar",
    "Blida",
    "Bouira",
    "Tamanrasset",
    "Tébessa",
    "Tlemcen",
    "Tiaret",
    "Tizi Ouzou",
    "Algiers",
    "Djelfa",
    "Jijel",
    "Sétif",
    "Saïda",
    "Skikda",
    "Sidi Bel Abbès",
    "Annaba",
    "Guelma",
    "Constantine",
    "Médéa",
    "Mostaganem",
    "M'Sila",
    "Mascara",
    "Ouargla",
    "Oran",
    "El Bayadh",
    "Illizi",
    "Bordj Bou Arréridj",
    "Boumerdès",
    "El Tarf",
    "Tindouf",
    "Tissemsilt",
    "El Oued",
    "Khenchela",
    "Souk Ahras",
    "Tipaza",
    "Mila",
    "Aïn Defla",
    "Naâma",
    "Aïn Témouchent",
    "Ghardaïa",
    "Relizane",
    "Timimoun",
    "Bordj Badji Mokhtar",
    "Ouled Djellal",
    "Béni Abbès",
    "In Salah",
    "In Guezzam",
    "Touggourt",
    "Djanet",
    "El M'Ghair",
    "El Menia"
  ];

  // List of available roles
  final List<String> _roles = ["Dentist", "Doctor", "Pharmacist", "Supplier"];

  // Define teal color
  final Color tealColor = Color(0xFF008080);

  @override
  Widget build(BuildContext context) {
    final termsAccepted = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);

    // Form controllers
    final firstNameController = useTextEditingController();
    final lastNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final phoneController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();

    // Form state
    final selectedWilaya = useState<String?>(null);
    final passwordVisible = useState(false);
    final confirmPasswordVisible = useState(false);
    final currentStep = useState(0);

    // Role state - initialize with passed role if available
    final roleState = useState<String?>(selectedRole);

    // Use our custom teal color instead of the theme's primary color
    final primaryColor = tealColor;
    final textTheme = Theme.of(context).textTheme;

    // Steps in registration process - add role selection step if needed
    final steps = selectedRole != null
        ? ['Personal Info', 'Contact', 'Security', 'Location']
        : [
            'Role Selection',
            'Personal Info',
            'Contact',
            'Security',
            'Location'
          ];

    // Handle registration
    Future<void> register() async {
      if (!formKey.currentState!.validate()) return;
      if (!termsAccepted.value) {
        _showErrorDialog(
            context,
            "Please accept the Terms of Use and Privacy Policy to continue.",
            primaryColor);
        return;
      }

      isLoading.value = true;

      try {
        final response = await http.post(
          Uri.parse("http://192.168.43.101:8000/api/register"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "first_name": firstNameController.text,
            "last_name": lastNameController.text,
            "email": emailController.text,
            "phone_number": phoneController.text,
            "wilaya": selectedWilaya.value,
            "role": roleState.value, // Use the role from state
            "password": passwordController.text,
            "password_confirmation": confirmPasswordController.text,
          }),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => SuccessScreen()));
        } else {
          _showErrorDialog(context,
              responseData['message'] ?? "Registration failed.", primaryColor);
        }
      } catch (e) {
        _showErrorDialog(
            context, "An error occurred. Please try again.", primaryColor);
      }

      isLoading.value = false;
    }

    // Step indicators
    Widget buildStepIndicators() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(steps.length, (index) {
            bool isActive = index <= currentStep.value;
            bool isCurrent = index == currentStep.value;

            return Row(
              children: [
                if (index > 0)
                  Container(
                    width: 15,
                    height: 1,
                    color: isActive ? primaryColor : Colors.grey.shade300,
                  ),
                Container(
                  width: isCurrent ? 35 : 30,
                  height: isCurrent ? 35 : 30,
                  decoration: BoxDecoration(
                    color: isActive ? primaryColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 15,
                    height: 1,
                    color: isActive && index < currentStep.value
                        ? primaryColor
                        : Colors.grey.shade300,
                  ),
              ],
            );
          }),
        ),
      );
    }

    // Handle step navigation
    void nextStep() {
      if (formKey.currentState!.validate()) {
        if (currentStep.value == 0 &&
            selectedRole == null &&
            !termsAccepted.value) {
          _showErrorDialog(
              context,
              "Please accept the Terms of Use and Privacy Policy to continue.",
              primaryColor);
          return;
        }
        if (currentStep.value < steps.length - 1) {
          currentStep.value++;
        } else {
          register();
        }
      }
    }

    void previousStep() {
      if (currentStep.value > 0) {
        currentStep.value--;
      }
    }

    // Form step content
    Widget buildStepContent() {
      // Offset index if role is provided
      final stepOffset = selectedRole != null ? 0 : 1;

      switch (currentStep.value) {
        case 0:
          // If role is provided, this is Personal Info step
          // If role is not provided, this is Role Selection step
          if (selectedRole != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Personal Information",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Registering as: $selectedRole",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: firstNameController,
                  label: "First Name",
                  prefixIcon: Icons.person_outline,
                  primaryColor: primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "First name is required";
                    if (!RegExp(r"^[a-zA-Z\s-]+$").hasMatch(value))
                      return "Only letters, spaces, and hyphens";
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: lastNameController,
                  label: "Last Name",
                  prefixIcon: Icons.person_outline,
                  primaryColor: primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Last name is required";
                    if (!RegExp(r"^[a-zA-Z\s-]+$").hasMatch(value))
                      return "Only letters, spaces, and hyphens";
                    return null;
                  },
                ),
              ],
            );
          } else {
            // Role Selection Step
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose Your Role",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  context: context,
                  label: "Select Role",
                  prefixIcon: Icons.badge_outlined,
                  selectedValue: roleState.value,
                  items: _roles,
                  onChanged: (value) => roleState.value = value,
                  validator: (value) =>
                      value == null ? "Role is required" : null,
                  searchable: false,
                  primaryColor: primaryColor,
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "About Roles",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Your role defines what you can do in the system. Choose the role that best matches your needs.",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: termsAccepted.value,
                        onChanged: (bool? value) {
                          termsAccepted.value = value ?? false;
                        },
                        activeColor: primaryColor,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "I agree to HealthLink's",
                              style: TextStyle(fontSize: 14),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          TermsDialogue(isTerms: true),
                                    );
                                  },
                                  child: Text(
                                    "Terms of Use",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(" and ", style: TextStyle(fontSize: 14)),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          TermsDialogue(isTerms: false),
                                    );
                                  },
                                  child: Text(
                                    "Privacy Policy",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

        case 1:
          // If role is provided, this is Contact step
          // If role is not provided, this is Personal Info step
          if (selectedRole != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Contact Information",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: emailController,
                  label: "Email Address",
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  primaryColor: primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Email is required";
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                      return "Enter a valid email";
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: phoneController,
                  label: "Phone Number",
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  primaryColor: primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Phone number is required";
                    if (!RegExp(r'^\d+$').hasMatch(value))
                      return "Enter a valid phone number";
                    return null;
                  },
                ),
              ],
            );
          } else {
            // Personal Info
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Personal Information",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Registering as: ${roleState.value}",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: firstNameController,
                  label: "First Name",
                  prefixIcon: Icons.person_outline,
                  primaryColor: primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "First name is required";
                    if (!RegExp(r"^[a-zA-Z\s-]+$").hasMatch(value))
                      return "Only letters, spaces, and hyphens";
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: lastNameController,
                  label: "Last Name",
                  prefixIcon: Icons.person_outline,
                  primaryColor: primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Last name is required";
                    if (!RegExp(r"^[a-zA-Z\s-]+$").hasMatch(value))
                      return "Only letters, spaces, and hyphens";
                    return null;
                  },
                ),
              ],
            );
          }

        case 2:
          // Security or Contact based on whether role was provided
          if (selectedRole != null) {
            // Security
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set Password",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: passwordController,
                  label: "Password",
                  prefixIcon: Icons.lock_outline,
                  obscureText: !passwordVisible.value,
                  primaryColor: primaryColor,
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: primaryColor,
                    ),
                    onPressed: () =>
                        passwordVisible.value = !passwordVisible.value,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Password is required";
                    if (value.length < 8)
                      return "Password must be at least 8 characters";
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: confirmPasswordController,
                  label: "Confirm Password",
                  prefixIcon: Icons.lock_outline,
                  obscureText: !confirmPasswordVisible.value,
                  primaryColor: primaryColor,
                  suffixIcon: IconButton(
                    icon: Icon(
                      confirmPasswordVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: primaryColor,
                    ),
                    onPressed: () => confirmPasswordVisible.value =
                        !confirmPasswordVisible.value,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Please confirm your password";
                    if (value != passwordController.text)
                      return "Passwords do not match";
                    return null;
                  },
                ),
              ],
            );
          } else {
            // Contact
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Contact Information",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: emailController,
                  label: "Email Address",
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  primaryColor: primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Email is required";
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                      return "Enter a valid email";
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: phoneController,
                  label: "Phone Number",
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  primaryColor: primaryColor,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Phone number is required";
                    if (!RegExp(r'^\d+$').hasMatch(value))
                      return "Enter a valid phone number";
                    return null;
                  },
                ),
              ],
            );
          }

        case 3:
          // Location or Security based on whether role was provided
          if (selectedRole != null) {
            // Location
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Location",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  context: context,
                  label: "Wilaya",
                  prefixIcon: Icons.location_on_outlined,
                  selectedValue: selectedWilaya.value,
                  items: _wilayas,
                  onChanged: (value) => selectedWilaya.value = value,
                  validator: (value) =>
                      value == null ? "Wilaya is required" : null,
                  searchable: true,
                  primaryColor: primaryColor,
                ),
              ],
            );
          } else {
            // Security
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set Password",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: passwordController,
                  label: "Password",
                  prefixIcon: Icons.lock_outline,
                  obscureText: !passwordVisible.value,
                  primaryColor: primaryColor,
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: primaryColor,
                    ),
                    onPressed: () =>
                        passwordVisible.value = !passwordVisible.value,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Password is required";
                    if (value.length < 8)
                      return "Password must be at least 8 characters";
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: confirmPasswordController,
                  label: "Confirm Password",
                  prefixIcon: Icons.lock_outline,
                  obscureText: !confirmPasswordVisible.value,
                  primaryColor: primaryColor,
                  suffixIcon: IconButton(
                    icon: Icon(
                      confirmPasswordVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: primaryColor,
                    ),
                    onPressed: () => confirmPasswordVisible.value =
                        !confirmPasswordVisible.value,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Please confirm your password";
                    if (value != passwordController.text)
                      return "Passwords do not match";
                    return null;
                  },
                ),
              ],
            );
          }

        case 4:
          // This is always Location for the no-role-provided case
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Location",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildDropdownField(
                context: context,
                label: "Wilaya",
                prefixIcon: Icons.location_on_outlined,
                selectedValue: selectedWilaya.value,
                items: _wilayas,
                onChanged: (value) => selectedWilaya.value = value,
                validator: (value) =>
                    value == null ? "Wilaya is required" : null,
                searchable: true,
                primaryColor: primaryColor,
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: termsAccepted.value,
                      onChanged: (bool? value) {
                        termsAccepted.value = value ?? false;
                      },
                      activeColor: primaryColor,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "I agree to HealthLink's",
                            style: TextStyle(fontSize: 14),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        TermsDialogue(isTerms: true),
                                  );
                                },
                                child: Text(
                                  "Terms of Use",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(" and ", style: TextStyle(fontSize: 14)),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        TermsDialogue(isTerms: false),
                                  );
                                },
                                child: Text(
                                  "Privacy Policy",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

        default:
          return SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentStep.value > 0)
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: primaryColor),
                          onPressed: previousStep,
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: primaryColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      Text(
                        steps[currentStep.value],
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                ),

                // Step indicators
                buildStepIndicators(),

                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildStepContent(),
                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isLoading.value ? null : nextStep,
                      child: isLoading.value
                          ? LoadingAnimationWidget.threeArchedCircle(
                              color: Colors.white,
                              size: 30,
                            )
                          : Text(
                              currentStep.value < steps.length - 1
                                  ? "Continue"
                                  : "Register",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                // Login link
                if (currentStep.value == 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?"),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          ),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required FormFieldValidator<String> validator,
    required Color primaryColor,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String? selectedValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required FormFieldValidator<String?> validator,
    required Color primaryColor,
    IconData? prefixIcon,
    bool searchable = false,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down),
      dropdownColor: Colors.white,
      menuMaxHeight: 300,
    );
  }
}

// Error dialog
void _showErrorDialog(
    BuildContext context, String message, Color primaryColor) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 10),
          Text("Error"),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("OK", style: TextStyle(color: primaryColor)),
        ),
      ],
    ),
  );
}

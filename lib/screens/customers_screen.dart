// lib/screens/customers_screen.dart - UPDATED CONTENT

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym/providers/customer_provider.dart';
import 'package:gym/models/customer.dart';
import 'package:gym/screens/customer_profile_screen.dart'; // Hypothetical screen
import 'package:gym/screens/add_customer_screen.dart'; // NEW

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                Provider.of<CustomerProvider>(context, listen: false).searchCustomers(query);
              },
            ),
          ),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                if (customerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (customerProvider.customers.isEmpty) {
                  return const Center(child: Text('No customers found.'));
                } else {
                  return ListView.builder(
                    itemCount: customerProvider.customers.length,
                    itemBuilder: (context, index) {
                      final customer = customerProvider.customers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              customer.firstName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text('${customer.firstName} ${customer.lastName}'),
                          subtitle: Text(customer.email),
                          onTap: () {
                            // Navigate to a hypothetical CustomerProfileScreen
                            // We can also pass the customer object to an edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerProfileScreen(customer: customer),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              _confirmDelete(context, customerProvider, customer);
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the AddCustomerScreen for adding new customers
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCustomerScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomerProvider customerProvider, Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete ${customer.firstName} ${customer.lastName}? This will also delete associated memberships.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                customerProvider.deleteCustomer(customer.customerId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${customer.firstName} deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Keep the CustomerProfileScreen as a hypothetical example for detailed view/edit
class CustomerProfileScreen extends StatelessWidget {
  final Customer customer;
  const CustomerProfileScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${customer.firstName} ${customer.lastName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${customer.email}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Phone: ${customer.phoneNumber ?? "N/A"}'),
                Text('Address: ${customer.address ?? "N/A"}'),
                Text('Joined: ${customer.dateJoined.toLocal().toString().split(' ')[0]}'),
                // Add more customer details here
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to AddCustomerScreen for editing
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddCustomerScreen(customer: customer),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
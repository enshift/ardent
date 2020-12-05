public with sharing class TestContact extends Model {
  static {
    register(TestContact.class, Contact.getSObjectType());
  }
}

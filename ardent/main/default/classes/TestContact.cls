public with sharing class TestContact extends Model {
  static {
    setTypes(TestContact.class, Contact.getSObjectType());
  }
}

public with sharing class TestAccount extends Model {
  static {
    setTypes(TestAccount.class, Account.getSObjectType());
  }
}

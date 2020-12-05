public with sharing class TestAccount extends Model {
  static {
    register(TestAccount.class, Account.getSObjectType());
  }
}

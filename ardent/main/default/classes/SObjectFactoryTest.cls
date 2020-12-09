@isTest
private class SObjectFactoryTest {
  @isTest
  static void shouldReceiveUniqueIdPerKeyPrefix() {
    Account firstAccount = (Account) SObjectFactory.newInstance(
        Schema.Account.getSObjectType()
      )
      .forgeSingle();

    Case caseInstance = (Case) SObjectFactory.newInstance(
        Schema.Case.getSObjectType()
      )
      .forgeSingle();

    Account secondAccount = (Account) SObjectFactory.newInstance(
        Schema.Account.getSObjectType()
      )
      .forgeSingle();

    System.assertEquals(Id.valueOf('001000000000001'), firstAccount.Id);
    System.assertEquals(Id.valueOf('500000000000001'), caseInstance.Id);
    System.assertEquals(Id.valueOf('001000000000002'), secondAccount.Id);
  }

  @isTest
  private static void canWriteToImmutableField() {
    String caseNumber = '0000001';

    Case caseInstance = (Case) SObjectFactory.newInstance(
        Schema.Case.getSObjectType()
      )
      .forgeSingle();

    try {
      caseInstance.put(Case.CaseNumber, caseNumber);
    } catch (Exception e) {
      System.assertEquals(SObjectException.class.getName(), e.getTypeName());
    }

    Case writeableCaseInstance = (Case) SObjectFactory.newInstance(
        Schema.Case.getSObjectType()
      )
      .setField(Schema.Case.CaseNumber, caseNumber)
      .forgeSingle();

    System.assertNotEquals(caseNumber, caseInstance.CaseNumber);
    System.assertEquals(caseNumber, writeableCaseInstance.CaseNumber);
  }

  @isTest
  private static void canSetChildrenOnSObject() {
    List<Contact> contacts = (List<Contact>) SObjectFactory.newInstance(
        Schema.Contact.getSobjectType()
      )
      .shouldGenerateId(true)
      .forge(5);
    Account parentAccount = (Account) SObjectFactory.newInstance(
        Schema.Account.getSObjectType()
      )
      .shouldGenerateId(true)
      .forgeSingle();
    Account parentAccountWithContacts = (Account) SObjectFactory.addChildren(
      parentAccount,
      Schema.Contact.getSObjectType(),
      Contact.AccountId,
      contacts
    );

    System.assertNotEquals(
      null,
      parentAccountWithContacts.Contacts,
      'Account Contact children should be set.'
    );
    System.assertEquals(
      5,
      parentAccountWithContacts.Contacts.size(),
      'Account should have exactly 5 Contact children.'
    );

    for (Contact childContact : parentAccountWithContacts.Contacts) {
      System.assertEquals(
        parentAccount.Id,
        childContact.AccountId,
        'Parent Lookup field on Account Contact child was not set.'
      );
      System.assertEquals(
        parentAccount,
        childContact.Account,
        'Parent Account on Contact child was not set.'
      );
    }
  }

  @isTest
  static void canAddChildren() {
    Account account = (Account) SObjectFactory.newInstance(
        Schema.Account.getSObjectType()
      )
      .setChildren(
        Schema.Contact.AccountId,
        SObjectFactory.newInstance(Schema.Contact.getSObjectType())
          .setNumberOfSObjects(5)
      )
      .forgeSingle();

    System.assertNotEquals(
      null,
      account.Contacts,
      'Account Contact children should be set.'
    );
    System.assertEquals(
      5,
      account.Contacts.size(),
      'Account should have exactly 5 Contact children.'
    );

    for (Contact childContact : account.Contacts) {
      System.assertEquals(
        account.Id,
        childContact.AccountId,
        'Parent Lookup field on Account Contact child was not set.'
      );
    }
  }

  @isTest
  private static void canAddDirectParentRelationship() {
    Contact contact = (Contact) SObjectFactory.newInstance(
        Schema.Contact.getSObjectType()
      )
      .addParentRelationship('Account')
      .forgeSingle();

    System.assertNotEquals(null, contact.Id, 'Contact Id is set');
    System.assertNotEquals(
      null,
      contact.AccountId,
      'Parent Account lookup Id should be set on the Contact'
    );
    System.assertNotEquals(
      null,
      contact.Account,
      'Parent Account relationship should be set on Contact'
    );
  }

  @isTest
  private static void canAddDistantParentRelationship() {
    Contact contact = (Contact) SObjectFactory.newInstance(
        Schema.Contact.getSobjectType()
      )
      .addParentRelationship('Account.Owner')
      .forgeSingle();

    System.assertNotEquals(null, contact.Id, 'Contact Id is set');
    System.assertNotEquals(
      null,
      contact.AccountId,
      'Parent Account lookup Id should be set on the Contact'
    );
    System.assertNotEquals(
      null,
      contact.Account,
      'Parent Account relationship should be set on Contact'
    );
    System.assertNotEquals(
      null,
      contact.Account.OwnerId,
      'Parent Account OwnerId lookup should be set on Contact'
    );
    System.assertNotEquals(
      null,
      contact.Account.Owner,
      'Parent Account Owner relationship should be set on Contact'
    );
  }

  @isTest
  private static void canAddMultipleParentRelationships() {
    Contact contact = (Contact) SObjectFactory.newInstance(
        Schema.Contact.getSobjectType()
      )
      .addParentRelationship('Account.Owner')
      .addParentRelationship('ReportsTo.Owner')
      .forgeSingle();

    System.assertNotEquals(
      null,
      contact.Account,
      'Parent Account relationship should be set on Contact'
    );
    System.assertNotEquals(
      null,
      contact.Account.Owner,
      'Parent Account Owner relationship should be set on Contact'
    );
    System.assertNotEquals(
      null,
      contact.ReportsTo,
      'ReportsTo relationship should be set on Contact'
    );
    System.assertNotEquals(
      null,
      contact.ReportsTo.Owner,
      'ReportsTo Owner relationship should be set on Contact'
    );
  }

  @isTest
  private static void canGetParentSObjects() {
    Contact contact = (Contact) SObjectFactory.newInstance(
        Schema.Contact.getSobjectType()
      )
      .addParentRelationship('Account.Owner')
      .forgeSingle();

    Object account = SObjectFactory.getParent(contact, 'Account');
    Object user = SObjectFactory.getParent(contact, 'Account.Owner');

    System.assertNotEquals(
      null,
      contact.Account,
      'Account should not return null'
    );
    System.assertNotEquals(
      null,
      contact.Account.Owner,
      'Account.Owner should not return null'
    );
    System.assertNotEquals(null, account, 'Account should not return null');
    System.assertNotEquals(null, user, 'Account.Owner should not return null');
    System.assertEquals(
      true,
      account instanceof Account,
      'Account should return an Account'
    );
    System.assertEquals(
      true,
      user instanceof User,
      'Account.Owner should return a User'
    );
  }

  @isTest
  private static void canAddMultipleSharedParentRelationships() {
    Contact contact = (Contact) SObjectFactory.newInstance(
        Schema.Contact.getSobjectType()
      )
      .addParentRelationship('Account.Owner')
      .addParentRelationship('Account.Parent')
      .forgeSingle();

    System.assertNotEquals(
      null,
      contact.Account.Owner,
      'Shared Account relationships Owner should be set on Contact'
    );
    System.assertNotEquals(
      null,
      contact.Account.Parent,
      'Shared Account relationship Parent should be set on Contact'
    );
  }

  @isTest
  private static void testGetDeduplicatedRelationships() {
    List<String> duplicateRelationships = new List<String>{
      'Contact',
      'Contact.Owner',
      'Contact.Account.Owner',
      'Contact.Owner.Manager',
      'Account.Owner.ParentAccount',
      'Account.Owner.Manager',
      'Account'
    };

    List<String> uniqueRelationships = SObjectFactory.getDeduplicatedRelationships(
      duplicateRelationships
    );

    System.assertEquals(false, uniqueRelationships.contains('Contact'));
    System.assertEquals(false, uniqueRelationships.contains('Contact.Owner'));
    System.assertEquals(
      true,
      uniqueRelationships.contains('Contact.Account.Owner')
    );
    System.assertEquals(
      true,
      uniqueRelationships.contains('Contact.Owner.Manager')
    );
    System.assertEquals(
      true,
      uniqueRelationships.contains('Account.Owner.ParentAccount')
    );
    System.assertEquals(
      true,
      uniqueRelationships.contains('Account.Owner.Manager')
    );
    System.assertEquals(false, uniqueRelationships.contains('Account'));
  }

  @isTest
  private static void canSetParentRelationshipFields() {
    Contact contact = (Contact) SObjectFactory.newInstance(
        Schema.Contact.getSobjectType()
      )
      .setField('Email', 'email@address.dev')
      .setField('Account.Name', 'Child Account')
      .setField('Account.Parent.Name', 'Parent Account')
      .setField('Account.Owner.Name', 'The Owner')
      .setField('ReportsTo.FirstName', 'ReportsToContact')
      .forgeSingle();

    System.assertEquals('email@address.dev', contact.Email);
    System.assertEquals('Child Account', contact.Account.Name);
    System.assertEquals('Parent Account', contact.Account.Parent.Name);
    System.assertEquals('The Owner', contact.Account.Owner.Name);
    System.assertEquals('ReportsToContact', contact.ReportsTo.FirstName);
  }

  @isTest
  private static void canSetAddParentRelationshipAndSetField() {
    Contact contact = (Contact) SObjectFactory.newInstance(
        Schema.Contact.getSobjectType()
      )
      .addParentRelationship('Account.Owner')
      .setField('Account.Name', 'My Account Name')
      .setField('Account.Owner.Email', 'email@address.dev')
      .forgeSingle();

    System.assertEquals(
      'My Account Name',
      contact.Account.Name,
      'Account Name should be overridden'
    );
    System.assertEquals(
      'email@address.dev',
      contact.Account.Owner.Email,
      'Owner Email should be overridden'
    );
  }

  @isTest
  private static void isSetFieldCaseInsensitive() {
    Contact contact = (Contact) SObjectFactory.newInstance(
        Schema.Contact.getSobjectType()
      )
      .addParentRelationship('account.Owner')
      .setField('Account.name', 'My Account Name')
      .setField('AccounT.Owner.eMaIl', 'email@address.dev')
      .forgeSingle();

    System.assertEquals(
      'My Account Name',
      contact.Account.Name,
      'Account Name should be overridden'
    );
    System.assertEquals(
      'email@address.dev',
      contact.Account.Owner.Email,
      'Owner Email should be overridden'
    );
  }
}

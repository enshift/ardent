public with sharing abstract class Model {
  /**
   * Stores all model SObjectTypes by their model names.
   */
  private static Map<String, Schema.SObjectType> sobjectTypeByModelName;
  private static Integer globalUniqueKey = 0;

  public String key { get; private set; }
  public SObject record { get; private set; }

  static {
    sobjectTypeByModelName = new Map<String, Schema.SObjectType>();
  }

  public static void register(
    System.Type type,
    Schema.SObjectType sobjectType
  ) {
    sobjectTypeByModelName.put(type.getName(), sobjectType);
  }

  public static Schema.SObjectType getSObjectTypeFor(System.Type type) {
    return sobjectTypeByModelName.get(type.getName());
  }

  public static Model newInstance(System.Type type) {
    return newInstance(type, null);
  }

  public static Model newInstance(
    System.Type type,
    SObject sobjectInstance
  ) {
    Model modelInstance = (Model) Type.newInstance();
    Schema.SObjectType sobjectType = sobjectTypeByModelName.get(type.getName());

    if (sobjectInstance == null) {
      sobjectInstance = sobjectType.newSObject();
    }

    modelInstance.record = sobjectInstance;

    modelInstance.key = !String.isBlank(sobjectInstance.Id)
      ? String.valueOf(sobjectInstance.Id)
      : getUniqueKey();

    return modelInstance;
  }

  public static String getUniqueKey() {
    return String.valueOf(globalUniqueKey++);
  }
}

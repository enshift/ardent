public with sharing class Collection {
  public System.Type modelType { get; private set; }
  private Map<String, Model> modelByKey;

  public List<Model> models {
    get {
      return modelByKey.values();
    }
  }

  public static Collection newInstance(
    System.Type modelType,
    List<SObject> sobjects
  ) {
    Collection newCollection = new Collection(modelType);

    for (SObject sobjectInstance : sobjects) {
      Model modelInstance = Model.newInstance(modelType, sobjectInstance);

      newCollection.add(modelInstance);
    }

    return newCollection;
  }

  public static Collection newInstance(System.Type modelType) {
    Collection newCollection = new Collection(modelType);

    return newCollection;
  }

  public static Selector query(System.Type modelType) {
    Model modelInstance = (Model)modelType.newInstance();
    Schema.SObjectType sobjectType = Model.getSObjectTypeFor(modelType);

    return new Selector(sobjectType);
  }

  public Collection(System.Type modelType) {
    this.modelByKey = new Map<String, Model>();
    this.modelType = modelType;
  }

  public Collection add(Model modelInstance) {
    modelByKey.put(modelInstance.key, modelInstance);

    return this;
  }
}

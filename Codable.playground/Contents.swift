//: Playground - noun: a place where people can play

import UIKit

//MARK: - 基本model编码解码
//身份证号（涉及键值映射）
//名字
//年龄（涉及类型转换）
//性别（涉及null值处理）
//地址（涉及可选处理）
//特征（涉及处理数据嵌套）
//出生日期（处理日期问题）
//＊可选处理为服务器返回字段可能不存在，null处理为返回字段存在并且值可能为null情况
let json_basePerson = """
{
    "id": "210282199310100919",
    "name": "cishing",
    "age": "20",
    "sex": 0,
    "address": "xxxxxx",
    "feature": {
                 "height": "180cm",
                 "weight": "70kg"
                },
    "bornDate": "1993-10-10 12:24:24"
}
""".data(using: .utf8)!

//性别枚举
enum Sex: Int, Codable {
    
    case man
    case woman
    case undefind
}

//由于还要列举继承model的codable实现，所以基本model使用class，如果不考虑继承情况可以考虑使用struct
class Person: Codable {
    
    var ID_No: String
    var name: String
    var age: Int
    var sex: Sex
    var address: String?
    var height: String
    var weight: String
    var bornDate: Date
    
    init(ID_No: String, name: String, age: Int, sex: Sex, address: String?, height: String, weight: String, bornDate: Date) {
        
        self.ID_No = ID_No
        self.name = name
        self.age = age
        self.sex = sex
        self.address = address
        self.height = height
        self.weight = weight
        self.bornDate = bornDate
    }
    
    //以下代码为处理 键值映射 数据嵌套 类型转换等情况，如无需处理以下代码可省略
    private enum CodingKeys: String, CodingKey {
        
        //需要列举出所有情况，如果不需要编码、解码部分字段则不写
        case ID_No = "id"
        case name
        case age
        case sex
        case address
        case height
        case weight
        case bornDate
        case feature    //用于数据嵌套情况
    }
    
    //编码
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ID_No, forKey: .ID_No)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(sex, forKey: .sex)
        try container.encode(address, forKey: .address)
        
//        try container.encodeNil(forKey: .address)
//        try container.encodeIfPresent(address, forKey: .address)
        
        //＊如果address属性值为nil的情况下，encodeIfPresent方法编码后会直接去掉“address”这一字段，encode方法则保留该字段，字段值为“null”，相当于调用了encodeNil方法。属性值不为nil情况下两方法效果相同
        try container.encode(bornDate, forKey: .bornDate)
        var nestContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .feature)   //嵌套数据编码
        
        try nestContainer.encode(height, forKey: .height)
        try nestContainer.encode(weight, forKey: .weight)
    }
    
    //解码
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ID_No = try container.decode(String.self, forKey: .ID_No)
        name = try container.decode(String.self, forKey: .name)
        let stringAge = try container.decode(String.self, forKey: .age)
        age = Int(stringAge) ?? 0       //类型转换，转换失败给予默认值
        sex = try container.decodeNil(forKey: .sex) ? Sex.undefind : try container.decode(Sex.self, forKey: .sex)       //null值处理，如果为null给予默认值
        address = try container.decodeIfPresent(String.self, forKey: .address)
        bornDate = try container.decode(Date.self, forKey: .bornDate)
        
        //＊如果有超链接情况，可直接使用URL.self解码
        
        //嵌套数据处理
        let nestContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .feature)
        height = try nestContainer.decode(String.self, forKey: .height)
        weight = try nestContainer.decode(String.self, forKey: .weight)
    }
    
    var description: String {
        
        return "ID_No:\(ID_No), name:\(name), age:\(age), sex:\(sex), address:\(address ?? "optional address"), height:\(height), weight:\(weight), bornDate:\(bornDate)"
    }
}

//编码
let onePerson = Person(ID_No: "210282199310100919", name: "cishing", age: 24, sex: Sex.man, address: "xxxxxx", height: "180cm", weight: "70kg", bornDate: Date())

let encoder = JSONEncoder()
//encoder.dataEncodingStrategy = .base64    //可以处理二进制数据
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//dateFormatter.locale = Locale.init(identifier: "zh_CN")
//dateFormatter.timeZone = TimeZone.init(identifier: "Asia/Shanghai")
encoder.dateEncodingStrategy = .formatted(dateFormatter)    //处理日期问题

do {
    
    let onePersonData = try encoder.encode(onePerson)
    
    print("基本model编码\n" + (String(data: onePersonData, encoding: .utf8) ?? "optional string") + "\n")
    
} catch {
    
    print(error)
}

//解码
let decoder = JSONDecoder()
//decoder.dataDecodingStrategy = .base64    //可以处理二进制数据
decoder.dateDecodingStrategy = .formatted(dateFormatter)    //处理日期问题

do {

    let person = try decoder.decode(Person.self, from: json_basePerson)

    print("基本model解码\n" + person.description + "\n")

} catch {

    print(error)
}

//MARK: - 继承model编码解码
let json_baseStudent = """
{
    "id": "210282199310100919",
    "name": "cishing",
    "age": "20",
    "sex": 0,
    "address": "xxxxxx",
    "feature": {
                 "height": "180cm",
                 "weight": "70kg"
                },
    "bornDate": "2018-08-08 08:08:08",
    "grade": 99.5
}
""".data(using: .utf8)!

//学生类，继承自Person
//处理继承情况
class Student: Person {
    
    var grade: Double    //分数
    
    init(ID_No: String, name: String, age: Int, sex: Sex, address: String?, height: String, weight: String, bornDate: Date, grade: Double) {
        
        self.grade = grade
        
        super.init(ID_No: ID_No, name: name, age: age, sex: sex, address: address, height: height, weight: weight, bornDate: bornDate)
    }
    
    private enum CodingKeys: String, CodingKey {
        
        case grade
    }
    
    //必须重写相应编码、解码方法
    override func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(grade, forKey: .grade)
        
        try super.encode(to: encoder)
    }
    
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        grade = try container.decode(Double.self, forKey: .grade)
        
        try super.init(from: decoder)
    }
    
    override var description: String {
        
        return super.description + ", grade:\(grade)"
    }
}

//编码
let oneStudent = Student(ID_No: "210282199310100919", name: "cishing", age: 24, sex: Sex.man, address: "xxxxxxx", height: "180cm", weight: "70kg", bornDate: Date(), grade: 90.5)

do {
    
    let oneStudentData = try encoder.encode(oneStudent)
    
        print("继承model编码\n" + (String(data: oneStudentData, encoding: .utf8) ?? "optional string") + "\n")
    
} catch {
    
    print(error)
}

//解码
do {
    
    let student = try decoder.decode(Student.self, from: json_baseStudent)
    
        print("继承model解码\n" + student.description + "\n")
    
} catch {
    
    print(error)
}

//MARK: - 嵌套类型编码解码
class Bedroom: Codable {
    
    var roomNo: String
    var students: [Student]
    var leader: Person
    
    var description: String {
        
        var string = "roomNo:\(roomNo)\n"
        string += "students:["
        
        students.forEach {
            
            string += "{\($0.description)}"
        }
        
        string += "]\nleader:{\(leader.description)}\n"
        
        return string
    }
}

let json_nestString = """
{
    "roomNo": "1227",
    "students": [
        {
            "id": "210282199310100919",
            "name": "cishing",
            "age": "20",
            "sex": 0,
            "address": "xxxxxx",
            "feature": {
            "height": "180cm",
            "weight": "70kg"
            },
            "bornDate": "2018-08-08 08:08:08",
            "grade": 99.5
        },
        {
            "id": "210282199310100919",
            "name": "daming",
            "age": "20",
            "sex": null,
            "feature": {
            "height": "180cm",
            "weight": "70kg"
            },
            "bornDate": "2018-08-08 08:08:08",
            "grade": 99.5
        }
    ],
    "leader": {
        "id": "210282199310100919",
        "name": "leader",
        "age": "20",
        "sex": 0,
        "address": "xxxxxx",
        "feature": {
        "height": "180cm",
        "weight": "70kg"
        },
        "bornDate": "1993-10-10 12:24:24"
    }
}
""".data(using: .utf8)!

do {
    
    let bedRoom = try decoder.decode(Bedroom.self, from: json_nestString)

    print("嵌套类型解码\n" + bedRoom.description)
    
} catch {
    
    print(error)
}

//＊顶层直接为数组的数据格式，可以直接使用decoder.decode([<#数组元素类型#>].self, from: <#T##Data#>)方式解码
//＊顶层直接为字典的数据格式，可以直接使用decoder.decode([<#Key#>: <#Value#>].self, from: <#T##Data#>)方式解码


//MARK: - 字典类型解码为数组，数组编码为字典（键值个数不确定情况）
let json_arrayDictionary = """
{
    "Banana": {
        "points": 200,
        "description": "A banana grown in Ecuador."
    },
    "Orange": {
        "points": 100
    }
}
""".data(using: .utf8)!

struct GroceryStore: Codable {
    
    struct Product {
        
        let name: String    //Key值
        let points: Int
        let description: String?
    }
    
    var products: [Product]
    
    init(products: [Product] = []) {
        
        self.products = products
    }
    
    //因为键值对数量不确定，需要使用struct处理键值映射问题
    struct ProductKey: CodingKey {
        
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? { return nil }
        
        init?(intValue: Int) {
            return nil
        }
        
        static let points = ProductKey(stringValue: "points")!
        static let description = ProductKey(stringValue: "description")!
    }
    
    //编码
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: ProductKey.self)
        
        for product in products {
            
            let nameKey = ProductKey(stringValue: product.name)!
            
            var productContainer = container.nestedContainer(keyedBy: ProductKey.self, forKey: nameKey)     //将name作为键进行深层次编码
            
            try productContainer.encode(product.points, forKey: .points)
            try productContainer.encode(product.description, forKey: .description)
        }
    }
    
    //解码
    init(from decoder: Decoder) throws {
        
        var products = [Product]()
        
        //使用struct类型的CodingKey，会解析出所有Key，使用enum类型则需要列举出所有的Key，因为不确定Key的值和数量，所以使用struct类型
        let container = try decoder.container(keyedBy: ProductKey.self)
        
        for key in container.allKeys {
            
//            print(key)
            
            let productContainer = try container.nestedContainer(keyedBy: ProductKey.self, forKey: key)     //通过Key值进行深层次解码
            let points = try productContainer.decode(Int.self, forKey: .points)
            let description = try productContainer.decodeIfPresent(String.self, forKey: .description)
            
            //将Key转换为name
            let product = Product(name: key.stringValue, points: points, description: description)
            
            products.append(product)
        }
        
        self.init(products: products)
    }
}

print("字典类型解码为对象数组，对象数组编码为字典（键值个数不确定情况）")
let store = GroceryStore(products: [
    .init(name: "Grapes", points: 230, description: "A mixture of red and green grapes."),
    .init(name: "Lemons", points: 2300, description: "An extra sour lemon.")
    ])

print("The result of encoding a GroceryStore:")
let encodedStore = try encoder.encode(store)
print(String(data: encodedStore, encoding: .utf8)!)

let decodedStore = try decoder.decode(GroceryStore.self, from: json_arrayDictionary)

print("\nThe store is selling the following products:")
for product in decodedStore.products {
    print("\t\(product.name) (\(product.points) points)")
    if let description = product.description {
        print("\t\t\(description)")
    }
}

//MARK: - 区分数组中子、父类问题
//参考链接:https://medium.com/tsengineering/swift-4-0-codable-decoding-subclasses-inherited-classes-heterogeneous-arrays-ee3e180eb556
let json_drinks = """
{
    "drinks": [
                {
                    "type": "water",
                    "description": "All natural"
                },
                {
                    "type": "orange_juice",
                    "description": "Best drank with breakfast"
                },
                {
                    "type": "beer",
                    "description": "An alcoholic beverage, best drunk on fridays after work",
                    "alcohol_content": "5%"
                }
            ]
}
""".data(using: .utf8)!

class Drink: Decodable {    //父类
    var type: String
    var description: String
}

class Beer: Drink {         //子类
    var alcohol_content: String

    private enum CodingKeys: String, CodingKey {
        case alcohol_content
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.alcohol_content = try container.decode(String.self, forKey: .alcohol_content)
        try super.init(from: decoder)
    }
}

struct Drinks: Decodable {

    let drinks: [Drink]

    enum DrinksKey: CodingKey {
        case drinks
    }

    enum DrinkTypeKey: CodingKey {
        case type
    }

    enum DrinkTypes: String, Decodable {
        case water = "water"
        case orangeJuice = "orange_juice"
        case beer = "beer"
    }

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: DrinksKey.self)
        var drinksArrayForType = try container.nestedUnkeyedContainer(forKey: DrinksKey.drinks)     //无键容器（数组）

        var drinks = [Drink]()

        var drinksArray = drinksArrayForType    //在isAtEnd方法中不能直接使用drinksArrayForType进行解码（可以当做for循环理解）
        
        while !drinksArrayForType.isAtEnd {

            let drink = try drinksArrayForType.nestedContainer(keyedBy: DrinkTypeKey.self)
            let type = try drink.decode(DrinkTypes.self, forKey: .type)

            switch type {
            case .water, .orangeJuice:

                drinks.append(try drinksArray.decode(Drink.self))

            default:

                drinks.append(try drinksArray.decode(Beer.self))
            }
        }

        self.drinks = drinks
    }
}

do {
    let results = try decoder.decode(Drinks.self, from:json_drinks)
    
    print("\n区分数组中子、父类问题")
    
    for result in results.drinks {
        print(result.description)
        if let beer = result as? Beer {
            print(beer.alcohol_content)
        }
    }
} catch {

    print(error)
}


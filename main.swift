import SwiftUI

enum ColorPalette {
    static let primary = Color.brandPrimary
    static let background = Color.gray.opacity(0.1)
}


import SwiftUI

enum UIConstants {
    // Padding
    static let paddingSmall: CGFloat = 8
    static let paddingDefault: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    
    // Corner radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusDefault: CGFloat = 16
    static let cornerRadiusButton: CGFloat = 24
    static let cornerRadiusCard: CGFloat = 24

    // Sizes
    static let iconSize: CGFloat = 24
    static let imageSizeSmall: CGFloat = 120
    
    // Spacing
    static let spacingSmall: CGFloat = 8
    static let spacingDefault: CGFloat = 16
    static let spacingLarge: CGFloat = 24
}


import Foundation

class HttpRequestHelper {
    
    func GET(url: String, completion: @escaping (Data?, String?) -> Void  ) {
        
        //  Validar que la url sea válida
        guard let url = URL(string: url) else {
            completion(nil, "Error: cannot create URL")
            return
        }
        
        // Crear una solicitud
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        // Crear una sesión
        let urlSession = URLSession.shared
        
        urlSession.dataTask(with: urlRequest) { data, response, error in
            
            // Validar que no haya error
            guard error == nil else {
                completion(nil, "Error: problem calling GET")
                return
            }
            
            // Validar que hay datos
            guard let data = data else {
                completion(nil, "Error: no data")
                return
            }
            
            // Validar que la respuesta sea success (200)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completion(data, "Error: HTTP request failed")
                return
            }
            completion(data, nil)
            
            
        }
        .resume()
    }
}


struct ProductResponse: Identifiable, Decodable {
    let id: Int
    let title: String
    let price: Double
    let description: String
    let category: String
    let image: String
    let rates: [ProductRateResponse]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case price
        case description
        case category
        case image
        case rates = "rates_available"
    }
    
}

struct ProductRateResponse: Decodable {
    let rate: Double
    let count: Int
}

extension ProductResponse {
    func toDomain() -> Shoe {
        Shoe(id: id, title: title, price: price, description: description, category: category, image: image)
    }
}


import Foundation

class ProductService {
    
    let url = "https://sugary-wool-penguin.glitch.me/products"
    
    func getProducts(completion: @escaping ([Product]?, String?) -> Void) {
        HttpRequestHelper().GET(url: url) { data, error in
            
            // Validar que no haya error
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            // Validar que hay datos
            guard let data = data else {
                completion(nil, error)
                return
            }
            
            do {
                let products = try JSONDecoder().decode([ProductResponse].self, from: data).map { productResponse in
                    productResponse.toDomain()
                }
                completion(products, nil)
                
            } catch let decodingError {
                completion(nil, String(describing: decodingError))
            }
        }
    }
}


struct Product: Identifiable {
    let id: Int
    let title: String
    let price: Double
    let description: String
    let category: String
    let image: String
    var favorite: Bool
    var cart: Bool
}


import Foundation

class HomeViewModel: ObservableObject {
    @Published var state: UIState<[Product]> = .idle
    private let productService = ProductService()
    
    init(){
        getProducts()
    }
    
    func getProducts() {
        self.state = .loading
        
        productService.getProducts { data, message in
            
            DispatchQueue.main.async {
                if let data = data {
                    self.state = .success(data)
                } else {
                    self.state = .failure(message ?? "Unknown error")
                }
            }
        }
    }
}


import SwiftUI

struct ProductCardView: View {
    @StateObject var product: Product
    
    var body: some View {
        VStack (alignment:.leading, spacing: UIConstants.spacingSmall){
            AsyncImage(url: URL(string: product.image)) { image in
                image
                    .resizable()
                    .frame(height: UIConstants.imageSizeSmall)
            } placeholder: {
                ProgressView()
                    .frame(height: UIConstants.imageSizeSmall)
            }
            
            Text(product.title)
                .lineLimit(1)
                .font(.headline)
                .bold()
            
            HStack {
                Text(String(format: "$ %i", product.price))
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button {
                    product.favorite = !product.favorite
                } label: {
                    Image(systemName: "heart")
                        .resizable()
                        .frame(width: UIConstants.iconSize, height: UIConstants.iconSize)
                        .foregroundStyle(ColorPalette.primary)
                }

                Button {
                    product.cart = !product.cart
                } label: {
                    Image(systemName: "cart")
                        .resizable()
                        .frame(width: UIConstants.iconSize, height: UIConstants.iconSize)
                        .foregroundStyle(ColorPalette.primary)
                }
            }
        }
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadiusCard))
        .overlay {
            RoundedRectangle(cornerRadius: UIConstants.cornerRadiusCard)
                .stroke(lineWidth: 2)
                .foregroundStyle(ColorPalette.background)
        }
    }
}

#Preview {
    ProductCardView(product: Product(id: 1, title: "Adidas Samba", price: 200, description: "", category: "", image: "https://www.hustgt.com/cdn/shop/products/Tenis_Samba_OG_Blanco_BB6975_01_standard-removebg--triangle.png"))
}


import SwiftUI

struct ProductCardFavoriteView: View {
    @StateObject let product: Product
    
    var body: some View {
        VStack (alignment:.leading, spacing: UIConstants.spacingSmall){
            AsyncImage(url: URL(string: product.image)) { image in
                image
                    .resizable()
                    .frame(height: UIConstants.imageSizeSmall)
            } placeholder: {
                ProgressView()
                    .frame(height: UIConstants.imageSizeSmall)
            }
            
            Text(product.title)
                .lineLimit(1)
                .font(.headline)
                .bold()
            
            HStack {
                Text(String(format: "$ %i", product.price))
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Image(systemName: "heart")
                        .resizable()
                        .frame(width: UIConstants.iconSize, height: UIConstants.iconSize)
                        .foregroundStyle(ColorPalette.primary)
            }

            Button {
                    product.favorite = false
                } label: {
                    Text("Remove")
                                .padding(.horizontal, UIConstants.paddingLarge)
                                .padding(.vertical, UIConstants.paddingDefault)
                                .background(gender == selectedGender ? ColorPalette.primary : .white)
                                .foregroundStyle(gender == selectedGender ? .white : .gray)
                                .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadiusDefault))
                                .overlay {
                                    RoundedRectangle(cornerRadius: UIConstants.cornerRadiusDefault)
                                        .stroke(gender == selectedGender ? ColorPalette.primary : .gray, lineWidth: 1)
                                }
                                .onTapGesture {
                                    selectedGender = gender
                                }
                }
        }
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadiusCard))
        .overlay {
            RoundedRectangle(cornerRadius: UIConstants.cornerRadiusCard)
                .stroke(lineWidth: 2)
                .foregroundStyle(ColorPalette.background)
        }
    }
}

#Preview {
    ProductCardView(product: Product(id: 1, title: "Adidas Samba", price: 200, description: "", category: "", image: "https://www.hustgt.com/cdn/shop/products/Tenis_Samba_OG_Blanco_BB6975_01_standard-removebg--triangle.png"))
}


import SwiftUI

struct ProductCardCartView: View {
    @StateObject let product: Product
    
    var body: some View {
        VStack (alignment:.leading, spacing: UIConstants.spacingSmall){
            AsyncImage(url: URL(string: product.image)) { image in
                image
                    .resizable()
                    .frame(height: UIConstants.imageSizeSmall)
            } placeholder: {
                ProgressView()
                    .frame(height: UIConstants.imageSizeSmall)
            }
            
            Text(product.title)
                .lineLimit(1)
                .font(.headline)
                .bold()
            
            HStack {
                Text(String(format: "$ %i", product.price))
                    .font(.title3)
                    .bold()
                
                Spacer()

                Image(systemName: "cart")
                        .resizable()
                        .frame(width: UIConstants.iconSize, height: UIConstants.iconSize)
                        .foregroundStyle(ColorPalette.primary)
            }

            Button {
                    product.cart = false
                } label: {
                    Text("Remove")
                                .padding(.horizontal, UIConstants.paddingLarge)
                                .padding(.vertical, UIConstants.paddingDefault)
                                .background(gender == selectedGender ? ColorPalette.primary : .white)
                                .foregroundStyle(gender == selectedGender ? .white : .gray)
                                .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadiusDefault))
                                .overlay {
                                    RoundedRectangle(cornerRadius: UIConstants.cornerRadiusDefault)
                                        .stroke(gender == selectedGender ? ColorPalette.primary : .gray, lineWidth: 1)
                                }
                                .onTapGesture {
                                    selectedGender = gender
                                }
                }
        }
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadiusCard))
        .overlay {
            RoundedRectangle(cornerRadius: UIConstants.cornerRadiusCard)
                .stroke(lineWidth: 2)
                .foregroundStyle(ColorPalette.background)
        }
    }
}

#Preview {
    ProductCardView(product: Product(id: 1, title: "Adidas Samba", price: 200, description: "", category: "", image: "https://www.hustgt.com/cdn/shop/products/Tenis_Samba_OG_Blanco_BB6975_01_standard-removebg--triangle.png"))
}


import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "shoe") {
                HomeView()
            }
            
            Tab("Favorites", systemImage: "heart") {
                ProductFavoriteView()
            }
            
            Tab("Cart", systemImage: "cart") {
                ProductCartView()
            }
        }
        .tint(ColorPalette.primary)
    }
}

#Preview {
    ContentView()
}


import SwiftUI

struct HomeView: View {
    
    @State var search = ""
    
    let genders = ["All", "Men", "Women", "Kids"]
    @State var selectedGender = "All"
    @StateObject var viewModel = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack (spacing: UIConstants.spacingDefault){
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray )
                    TextField("Search", text: $search)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .background(ColorPalette.background)
                .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadiusSmall))
                
                Banner()
                
                ScrollView (.horizontal) {
                    HStack {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender)
                                .padding(.horizontal, UIConstants.paddingLarge)
                                .padding(.vertical, UIConstants.paddingDefault)
                                .background(gender == selectedGender ? ColorPalette.primary : .white)
                                .foregroundStyle(gender == selectedGender ? .white : .gray)
                                .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadiusDefault))
                                .overlay {
                                    RoundedRectangle(cornerRadius: UIConstants.cornerRadiusDefault)
                                        .stroke(gender == selectedGender ? ColorPalette.primary : .gray, lineWidth: 1)
                                }
                                .onTapGesture {
                                    selectedGender = gender
                                }
                        }
                    }
                }
           
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading")
                case .success(let products):
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(products) { product in
                            ProductCardView(product: product)
                        }
                    }
                case .failure(let message):
                    VStack {
                        Text("Error: \(message)")
                    }
                }
                    
                Spacer()

                ContentView()
            }
            .padding(UIConstants.paddingDefault)
        }
    }
}

#Preview {
    HomeView()
}


import SwiftUI

struct ProductFavoriteView: View {
    
    @State var search = ""
    
    @StateObject var viewModel = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack (spacing: UIConstants.spacingDefault){
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray )
                    TextField("Search", text: $search)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .background(ColorPalette.background)
                .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadiusSmall))
                
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading")
                case .success(let products):
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(products) { product in
                            if (product.favorite) {
                                ProductCardView(product: product)
                            }
                        }
                    }
                case .failure(let message):
                    VStack {
                        Text("Error: \(message)")
                    }
                }
                    
                Spacer()

                ContentView()
            }
            .padding(UIConstants.paddingDefault)
        }
    }
}

#Preview {
    ProductFavoriteView()
}


import SwiftUI

struct ProductCartView: View {
    
    @State var search = ""
    @State var priceTotal: Double = 0.0
    
    @StateObject var viewModel = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack (spacing: UIConstants.spacingDefault){
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray )
                    TextField("Search", text: $search)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding()
                .background(ColorPalette.background)
                .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadiusSmall))
                
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading")
                case .success(let products):
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(products) { product in
                            if (product.cart) {
                                priceTotal += product.price
                                ProductCardView(product: product)
                            }
                        }
                    }
                case .failure(let message):
                    VStack {
                        Text("Error: \(message)")
                    }
                }

                Text(priceTotal)
                    
                Spacer()

                ContentView()
            }
            .padding(UIConstants.paddingDefault)
        }
    }
}

#Preview {
    ProductCartView()
}
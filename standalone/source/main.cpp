#include <crow.h>
#include <greeter/greeter.h>
#include <greeter/version.h>

#include <iostream>
#include <string>
#include <unordered_map>

int main() {
  crow::SimpleApp app;

  // Example of a request taking URL parameters
  // If you want to activate all the functions just query
  // {ip}:3080/hello?language='blabla'
  CROW_ROUTE(app, "/hello")
  ([](const crow::request& req) {
    // check params
    std::cerr << "Params: " << req.url_params << "\n";
    std::cerr << "The key 'language' was "
              << (req.url_params.get("language") == nullptr ? "not " : "") << "found.\n";

    if (req.url_params.get("language") == nullptr) {
      // return bad request
      return crow::response(400, "please provide a 'language={en|de|es|fr}' argument");
    }
    const auto language = req.url_params.get("language");

    // see if langauge was found
    const std::unordered_map<std::string, greeter::LanguageCode> languages{
        {"en", greeter::LanguageCode::EN},
        {"de", greeter::LanguageCode::DE},
        {"es", greeter::LanguageCode::ES},
        {"fr", greeter::LanguageCode::FR},
    };
    const auto langIt = languages.find(language);
    if (langIt == languages.end()) {
      // return bad request
      std::cerr << "Greeting for language '" << language
                << "' is not available, use one of: [en, de, es, fr]\n";
      return crow::response(400, "language not recognized");
    }

    const greeter::Greeter greeter("Crow & Greeter");
    std::cout << "Greeting for language '" << language << "' is available, returning message\n";
    const auto message = greeter.greet(langIt->second);

    crow::json::wvalue ret({{"answer", message}});
    return crow::response(200, ret);
  });

  app.port(3080).multithreaded().run();
}

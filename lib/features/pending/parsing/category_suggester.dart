class CategorySuggester {
  static const List<String> _food = ['swiggy', 'zomato', 'domino', 'dominos'];
  static const List<String> _shopping = ['amazon', 'flipkart', 'myntra'];
  static const List<String> _travel = ['uber', 'ola', 'irctc'];
  static const List<String> _groceries = ['blinkit', 'bigbasket', 'zepto'];
  static const List<String> _bills = ['airtel', 'jio', 'electricity', 'bescom'];

  static String suggest(String merchant) {
    final text = merchant.toLowerCase();
    if (_food.any(text.contains)) return 'Food';
    if (_shopping.any(text.contains)) return 'Shopping';
    if (_travel.any(text.contains)) return 'Travel';
    if (_groceries.any(text.contains)) return 'Groceries';
    if (_bills.any(text.contains)) return 'Bills';
    return 'Others';
  }
}

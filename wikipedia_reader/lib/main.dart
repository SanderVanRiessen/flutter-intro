import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'summary.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ArticleView());
  }
}

class ArticleModel {
  Future<Summary> getRandomArticleSummary() async {
    final uri = Uri.https(
      'en.wikipedia.org',
      '/api/rest_v1/page/random/summary',
    );
    final response = await get(uri);

    if (response.statusCode != HttpStatus.ok) {
      throw const HttpException('Failed to fetch article summary');
    }

    return Summary.fromJson(jsonDecode(response.body) as Map<String, Object?>);
  }
}

class ArticleViewModel extends ChangeNotifier {
  final ArticleModel model;
  Summary? summary;
  Exception? error;
  bool isLoading = false;

  ArticleViewModel(this.model) {
    fetchArticle();
  }

  Future<void> fetchArticle() async {
    isLoading = true;
    notifyListeners();

    try {
      summary = await model.getRandomArticleSummary();
      error = null;
    } on HttpException catch (e) {
      summary = null;
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class ArticleView extends StatelessWidget {
  ArticleView({super.key});

  final articleViewModel = ArticleViewModel(ArticleModel());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Wikipedia Summary Example')),
        body: ListenableBuilder(
          listenable: articleViewModel,
          builder: (context, _) {
            return switch ((
              articleViewModel.isLoading,
              articleViewModel.summary,
              articleViewModel.error,
            )) {
              (true, _, _) => const Center(child: CircularProgressIndicator()),
              (_, _, final Exception e) => Text('Error: ${e.toString()}'),
              (false, final summary?, null) => ArticlePage(
                summary: summary,
                nextArticleCallback: articleViewModel.fetchArticle,
              ),
              _ => const Text('something went wrong'),
            };
          },
        ),
      ),
    );
  }
}

class ArticlePage extends StatelessWidget {
  const ArticlePage({
    super.key,
    required this.summary,
    required this.nextArticleCallback,
  });

  final Summary summary;
  final VoidCallback nextArticleCallback;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ArticleWidget(summary: summary),
          ElevatedButton(
            onPressed: nextArticleCallback,
            child: Text('Next random article'),
          ),
        ],
      ),
    );
  }
}

class ArticleWidget extends StatelessWidget {
  const ArticleWidget({super.key, required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        spacing: 10,
        children: [
          if (summary.hasImage) Image.network(summary.originalImage!.source),
          Text(
            summary.titles.normalized,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          if (summary.description != null)
            Text(
              summary.description!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(summary.extract),
        ],
      ),
    );
  }
}

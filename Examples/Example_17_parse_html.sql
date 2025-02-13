-----------------------------------------------------------------------------
--Парсинг (разбор) html-документа (с помощью пакета html_io)-----------------
-----------------------------------------------------------------------------
do
LANGUAGE pl_cpl_sql
$$
declare 
    html_doc html := '
<!DOCTYPE HTML>
<html ng-app="LazarusPackages">

<head>
    <meta charset="UTF-8">
    <title>Lazarus Packages</title>
	<!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <!-- Material Design for Bootstrap fonts and icons -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700|Material+Icons">

    <!-- Material Design for Bootstrap CSS -->
    <link rel="stylesheet" href="https://unpkg.com/bootstrap-material-design@4.1.1/dist/css/bootstrap-material-design.min.css" integrity="sha384-wXznGJNEXNG1NFsbm0ugrLFMQPWswR3lds2VeinahP8N0zJw9VWSopbjv2x7WCvX" crossorigin="anonymous">

    <!-- Angular -->
    <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.8.0/angular.min.js"></script>

    <!-- Application -->
    <script src="main.js"></script>
    <script src="mark.min.js"></script>
    <style>
        .card {
            margin: 15px;
            min-width: 90%;
            max-width: 90vw;
        }
        mark {
            padding: 0px;
        }
    </style>
</head>

<body ng-controller="PackagesController as pc">
    <!-- Header -->
    <nav class="navbar navbar-light bg-light sticky-top">
        <div class="container">
            <a class="navbar-brand" href="#">Lazarus Packages</a>
            <!-- Search and Categories -->
            <form class="form-group">
                <input class="form-control" type="text" ng-model="pc.searchText" ng-change="pc.markText()" ng-model-options="{debounce:250}" placeholder="Search">
                <select class="form-control" ng-model="pc.selectedCategory">
                    <option value="{{category.toString().toLowerCase()}}" ng-repeat="category in pc.categories">{{category.toString()}}</option>
                </select>
            </form>
        </div>
    </nav>
    <div class="container">
        <div class="row">
            <div class="content">
                <!-- Package data -->
                <div class="card" ng-repeat="package in pc.packages" ng-show="pc.show($index)">
                    <div class="card-header">
                        <h4 class="card-title">{{package.data.DisplayName}}</h4>
                        <h6 class="card-subtitle mb-2 text-muted">{{package.data.Category}}</h6>
                        <a href="{{package.data.RepositoryFileName}}" class="card-link">Download</a>
                        <a ng-show="package.data.HomePageURL" href="{{package.data.HomePageURL}}" class="card-link">Home Page</a>
                    </div>
                    <!-- Package files -->
                    <div class="card-body" ng-repeat="files in package.files">
                        <p ng-show="files.Name"><strong>Package:</strong> {{files.Name}}</p>
                        <p ng-show="files.Author"><strong>Author:</strong> {{files.Author}}</p>
                        <p ng-show="files.Description"><strong>Description:</strong> {{files.Description}}</p>
                        <p ng-show="files.License"><strong>License:</strong> {{files.License | limitTo:200}}{{files.License.length > 200 ? ''...'' : ''''}}</p>
                        <p ng-show="files.Dependencies"><strong>Dependencies:</strong> {{files.DependenciesAsString}}</p>
                        <p ng-show="files.VersionAsString"><strong>Version:</strong> {{files.VersionAsString}}</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>

</html>';

begin 
   dbms_output.put_line('----Start---');
  
   --Обходим массив с разобранными вершинами html-документа
   for i in 1..html_io.get_node_count(html_doc) loop 
     --Выводим полную информацию про вершины на экран
     dbms_output.put_line('level='||html_io.get_node_prop(html_doc, i, 'level')||                          
     					  ', type='||html_io.get_node_prop(html_doc, i, 'type')||
                          ', path='||html_io.get_node_prop(html_doc, i, 'path')||
                          ', name='||html_io.get_node_prop(html_doc, i, 'name')||
						  ', val='||html_io.get_node_prop(html_doc, i, 'value')||	                          
                          ', attrs='||html_io.get_node_all_attr(html_doc,i)
                         );
   end loop; 
end; 
$$
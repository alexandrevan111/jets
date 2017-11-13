resources :posts
# resources :posts expands to:
# get "posts", to: "posts#index"
# get "posts/new", to: "posts#new"
# get "posts/:id", to: "posts#show"
# post "posts", to: "posts#create"
# get "posts/:id/edit", to: "posts#edit"
# put "posts/:id", to: "posts#update"
# delete "posts/:id", to: "posts#delete"

any "comments/hot", to: "comments#hot"
get "landing/posts", to: "posts#index"
get "landing/comments", to: "comments#hot"

get "admin/pages", to: "admin/pages#index"
get "related_posts/:id", to: "related_posts#show"

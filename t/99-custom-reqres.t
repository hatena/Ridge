use Test::More;

use Ridge;
use Ridge::Config;

{
    package Test::App;
    use parent qw(Ridge);
    __PACKAGE__->config(Ridge::Config->new);
};

is ref(Test::App->make_request({})), "Ridge::Request";
is ref(Test::App->make_response), "Ridge::Response";

eval qq{
    package Test::App::Request;
    use parent qw(Ridge::Request);

    package Test::App::Response;
    use parent qw(Ridge::Response);
};

is ref(Test::App->make_request({})), "Test::App::Request";
is ref(Test::App->make_response), "Test::App::Response";

{
    package Test::App2;
    use parent qw(Ridge);
    __PACKAGE__->config(Ridge::Config->new);
};

is ref(Test::App2->make_request({})), "Ridge::Request";
is ref(Test::App2->make_response), "Ridge::Response";

eval qq{
    package Test::App2::Request;
    # no parent

    package Test::App2::Response;
    # no parent
};

is ref(Test::App2->make_request({})), "Ridge::Request";
is ref(Test::App2->make_response), "Ridge::Response";

done_testing;

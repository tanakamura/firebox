use std::thread;
use std::io::ErrorKind;
use tiny_http;

fn send_404(rq: tiny_http::Request) {
    let res = tiny_http::Response::from_string("404").with_status_code(404);
    let _ = rq.respond(res);
}

fn handle_req(rq: tiny_http::Request) {
    let url = rq.url().to_string();
    if url == "/" {
        let html = r#"<html><head><meta charset="utf-8"/></head><body><p>Welcome to FireBox!!</p><p>ようこそ！</p></body></html>"#;
        let res = tiny_http::Response::from_string(html.to_string())
            .with_header(tiny_http::Header{
                field: "Content-Type".parse().unwrap(),
                value: "text/html".parse().unwrap()
            });
        let _ = rq.respond(res);
    } else {
        send_404(rq);
    }
}

pub fn start_server() -> std::io::Result<()> {
    let server = tiny_http::Server::http("127.0.0.1:8080");

    if let Ok(server) = server {
        thread::spawn( move || {
            for rq in server.incoming_requests() {
                handle_req(rq);
            }
        });
    } else {
        return Err(std::io::Error::new(ErrorKind::Other, "oh!"));
    }


    Ok(())
}

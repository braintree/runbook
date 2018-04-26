require "spec_helper"

RSpec.describe Runbook::Viewer do
  let(:book) do
    Runbook.book "My Book" do
      section "Parent Section" do
        section "First Section" do
          step "Step 1" do
            note "I like cheese"
          end
        end

        section "Second Section" do
          step "Step 1" do
            confirm "Did you eat cheese today?"
          end
        end
      end
    end
  end
  let(:viewer) { Runbook::Viewer.new(book) }

  context "with markdown view" do
    let(:view) { :markdown }

    it "generates a markdown representation of the book" do
      markdown = viewer.generate(view)

      expect(markdown).to eq(<<-MARKDOWN)
# My Book

## 1. Parent Section

### 1. First Section

1. [] Step 1

   I like cheese

### 2. Second Section

1. [] Step 1

   confirm: Did you eat cheese today?

MARKDOWN
    end

    context "step" do
      context "with ssh_config" do
        let(:book) do
          Runbook.book "My Book" do
            section "Section" do
              step "Step" do
                servers "appserver01.prod", "appserver02.prod"
                parallelization strategy: :sequence
                path "/root"
                user "root"
                group "root"
                env rails_env: "production"
                umask "077"

                command %q{echo "hi"}
              end
            end
          end
        end

        it "renders the ssh_config within a step" do
          markdown = viewer.generate(view)

          expect(markdown).to eq(<<-MARKDOWN)
# My Book

## 1. Section

1. [] Step

   on: appserver01.prod, appserver02.prod
   in: sequence, wait: 2
   as: user: root group: root
   within: /root
   with: RAILS_ENV=production
   umask: 077

   run: `echo "hi"`

MARKDOWN
        end
      end

      context "with long server list" do
        server_list = [
          "appserver01.prod",
          "appserver02.prod",
          "appserver03.prod",
          "appserver04.prod",
          "appserver05.prod",
          "appserver06.prod",
          "appserver07.prod",
          "appserver08.prod",
        ]

        let(:book) do
          Runbook.book "My Book" do
            section "Section" do
              step "Step" do
                servers *server_list
                command %q{echo "hi"}
              end
            end
          end
        end

        it "renders an abbreviated server list" do
          markdown = viewer.generate(view)

          expect(markdown).to eq(<<-MARKDOWN)
# My Book

## 1. Section

1. [] Step

   on: appserver01.prod, appserver02.prod, app...od, appserver07.prod, appserver08.prod

   run: `echo "hi"`

MARKDOWN
        end
      end

      context "with groups parallelization strategy" do
        let(:book) do
          Runbook.book "My Book" do
            section "Section" do
              step "Step" do
                parallelization strategy: :groups, limit: 10, wait: 5
                command %q{echo "hi"}
              end
            end
          end
        end

        it "renders in: with limit and wait" do
          markdown = viewer.generate(view)

          expect(markdown).to eq(<<-MARKDOWN)
# My Book

## 1. Section

1. [] Step

   in: groups, limit: 10, wait: 5

   run: `echo "hi"`

MARKDOWN
        end
      end

      context "with parallel parallelization strategy" do
        let(:book) do
          Runbook.book "My Book" do
            section "Section" do
              step "Step" do
                parallelization strategy: :parallel, limit: 10, wait: 5
                command %q{echo "hi"}
              end
            end
          end
        end

        it "renders in without limit or wait" do
          markdown = viewer.generate(view)

          expect(markdown).to eq(<<-MARKDOWN)
# My Book

## 1. Section

1. [] Step

   in: parallel

   run: `echo "hi"`

MARKDOWN
        end
      end
    end
  end
end
